import assert from "node:assert/strict";
import test from "node:test";

const storage = new Map();
globalThis.localStorage = {
  getItem: key => storage.get(key) ?? null,
  setItem: (key, value) => storage.set(key, value),
  removeItem: key => storage.delete(key)
};
globalThis.window = {__TAURI__: {core: {}}};

function makeDom() {
  const makeNode = (tag = "div") => ({
    tag,
    className: "",
    textContent: "",
    type: "",
    value: "",
    style: {setProperty() {}},
    classList: {add() {}, remove() {}, toggle() {}, contains() { return false; }},
    children: [],
    get isConnected() { return body.children.includes(this); },
    get childElementCount() { return this.children.length; },
    matches: sel => sel === ".btn" && tag === "button",
    append(...items) { this.children.push(...items); },
    prepend(...items) { this.children.unshift(...items); },
    replaceChildren(...items) { this.children = items; },
    setAttribute() {},
    addEventListener() {},
    remove() {},
    onclick: null
  });
  const title = makeNode("h2");
  const body = makeNode("div");
  const makeDialog = () => {
    const listeners = new Map();
    return {
      open: false,
      showModal() { this.open = true; },
      close() {
        if (!this.open) return;
        this.open = false;
        for (const fn of [...(listeners.get("close") ?? [])]) fn();
      },
      addEventListener(type, fn, opts = {}) {
        if (!listeners.has(type)) listeners.set(type, []);
        const wrapped = opts.once ? () => {
          this.removeEventListener(type, wrapped);
          fn();
        } : fn;
        wrapped._orig = fn;
        listeners.get(type).push(wrapped);
      },
      removeEventListener(type, fn) {
        const list = listeners.get(type);
        if (!list) return;
        listeners.set(type, list.filter(item => item !== fn && item._orig !== fn));
      }
    };
  };
  const dialog = makeDialog();
  const recovery = makeDialog();
  globalThis.document = {
    querySelector(sel) {
      if (sel === "dialog[open]") return [dialog, recovery].find(item => item.open) ?? null;
      return {"dialog":dialog, "#dialogTitle":title, "#dialogBody":body}[sel] ?? makeNode();
    },
    createElement: makeNode,
    createElementNS: () => makeNode("svg")
  };
  return {dialog, recovery, title, body};
}

test("background check opens a non-forcing update dialog once per version and respects manual open", async () => {
  const {dialog, title, body} = makeDom();
  let release = {version: "0.2.0", notes: "Fix bug\nImprove speed"};
  window.__TAURI__.core.invoke = async command => {
    assert.equal(command, "check_app_update");
    return release;
  };
  const {state} = await import("../../apps/desktop/ui/state.js");
  const {checkApp, showRelease} = await import("../../apps/desktop/ui/app-update.js");
  state.locale = "en";

  await checkApp(false);
  assert.equal(dialog.open, true);
  assert.match(title.textContent, /0\.2\.0/);
  assert.equal(body.children[0].textContent, "Fix bug\nImprove speed");
  const buttons = body.children[1].children;
  assert.equal(buttons.length, 2);
  buttons[1].onclick();
  assert.equal(dialog.open, false);
  assert.equal(storage.get("dismissed-app-update"), "0.2.0");

  await checkApp(false);
  assert.equal(dialog.open, false);

  showRelease();
  assert.equal(dialog.open, true);
  dialog.close();

  release = {version: "0.2.1", notes: ""};
  await checkApp(false);
  assert.equal(dialog.open, true);
  assert.match(title.textContent, /0\.2\.1/);
  assert.match(body.children[0].textContent, /Settings/);
  dialog.close();
  assert.equal(storage.get("dismissed-app-update"), "0.2.1");

  await checkApp(true);
  assert.equal(dialog.open, true);
  dialog.close();
});

test("queued background update waits until an active dialog closes", async () => {
  storage.clear();
  const {dialog, title} = makeDom();
  dialog.open = true;
  window.__TAURI__.core.invoke = async () => ({version: "0.3.0", notes: "Queued release"});
  const {state} = await import("../../apps/desktop/ui/state.js");
  const {checkApp} = await import("../../apps/desktop/ui/app-update.js");
  state.locale = "zh-TW";
  state.release = null;

  await checkApp(false);
  assert.equal(dialog.open, true);
  assert.equal(title.textContent, "");

  dialog.close();
  assert.equal(dialog.open, true);
  assert.match(title.textContent, /0\.3\.0/);
  dialog.close();
});

test("a background release waits for the recovery prompt and any subsequent transaction dialog", async () => {
  const {dialog, recovery, title} = makeDom();
  const {checkApp} = await import("../../apps/desktop/ui/app-update.js");
  const reply = Promise.withResolvers();
  window.__TAURI__.core.invoke = () => reply.promise;
  const pending = checkApp(false);
  recovery.showModal();
  reply.resolve({version:"0.4.0", notes:"Release notes"});
  await pending;
  assert.equal(dialog.open, false);
  assert.equal(title.textContent, "");

  dialog.showModal();
  recovery.close();
  assert.equal(title.textContent, "");
  dialog.close();
  assert.equal(dialog.open, true);
  assert.match(title.textContent, /0\.4\.0/);
  dialog.close();
});

test("a late manual update result preserves installation progress and opens after close", async () => {
  const {dialog, title, body} = makeDom();
  const {checkApp} = await import("../../apps/desktop/ui/app-update.js");
  const reply = Promise.withResolvers();
  window.__TAURI__.core.invoke = () => reply.promise;
  const version = "0.5.0";
  storage.set("dismissed-app-update", version);
  const pending = checkApp(true);
  const progress = document.createElement("progress");
  title.textContent = "Installing";
  body.replaceChildren(progress);
  dialog.showModal();
  reply.resolve({version, notes:"Release notes"});
  await pending;
  assert.equal(title.textContent, "Installing");
  assert.deepEqual(body.children, [progress]);
  dialog.close();
  assert.equal(dialog.open, true);
  assert.match(title.textContent, /0\.5\.0/);
  dialog.close();
});

async function openModUpdate(releaseNotes) {
  const {body} = makeDom();
  const {state} = await import("../../apps/desktop/ui/state.js");
  const {renderModList} = await import("../../apps/desktop/ui/catalog-view.js");
  const name = {en:"Example", "zh-TW":"範例", "zh-CN":"示例"};
  const mod = {id:"example", repo:"org/example", version:"v2", name, summary:name,
    package:{sha256:"same"}, releaseNotes};
  const scan = {installed:{[mod.repo]:"v1"}, modStates:{example:"installed"}, pckDir:"copy"};
  const calls = [];
  Object.assign(state, {locale:"en", game:"copy", mods:[mod], updateTargets:[mod], scan:"ready",
    inventory:scan.installed, modStates:scan.modStates, packages:{example:"same"}});
  window.__TAURI__.core.invoke = async command => {
    calls.push(command);
    if (command === "game_process") return false;
    if (command === "game_copies") return ["copy"];
    if (command === "installed_versions") return scan.installed;
    if (command === "validate_game_mods") return scan;
    if (command === "update_mod") return {...scan, installed:{[mod.repo]:"v2"}};
    assert.equal(command, "verify_package");
  };
  const content = document.createElement("main");
  renderModList(content);
  const card = content.children.find(el => el.className === "grid").children[0];
  await card.children.find(el => el.className === "card-actions").children[0].onclick();
  const notes = () => body.children.find(el => el.className === "release-notes")?.textContent;
  const confirm = () => body.children.at(-1).children.at(-1).onclick();
  calls.length = 0;
  return {body, calls, confirm, notes, mod, state};
}

test("a mod update can be confirmed without notes for its version and language", async () => {
  for (const releaseNotes of [undefined, {version:"v2", "zh-TW":"更新"}, {version:"v2", en:"  "}, {version:"v1", en:"Old"}]) {
    const {body, calls, confirm} = await openModUpdate(releaseNotes);
    assert.deepEqual(body.children.map(el => el.tag), ["p", "div"]);
    assert.equal(body.children[0].textContent, "v1 → v2");
    await confirm();
    assert.deepEqual(calls, ["game_process", "verify_package", "game_process", "update_mod"]);
  }
});

test("a mod update requires fresh confirmation for new or revised notes", async () => {
  const {calls, confirm, notes, mod, state} = await openModUpdate();
  assert.equal(notes(), undefined);
  for (const en of ["Everyone must update", "Everyone must restart"]) {
    state.mods = [{...mod, releaseNotes:{version:mod.version, en}}];
    await confirm();
    assert.equal(notes(), en);
    assert.deepEqual(calls, []);
  }
  state.mods[0].releaseNotes["zh-TW"] = "請重新啟動";
  await confirm();
  assert.deepEqual(calls, ["game_process", "verify_package", "game_process", "update_mod"]);
});

test("withdrawing optional notes does not require another confirmation", async () => {
  const {calls, confirm, mod, state} = await openModUpdate({version:"v2", en:"First notes"});
  state.mods = [{...mod, releaseNotes:undefined}];
  await confirm();
  assert.deepEqual(calls, ["game_process", "verify_package", "game_process", "update_mod"]);
});

test("Steam restore keeps waiting across focus and cancels monitoring when dismissed", async () => {
  const {dialog, body} = makeDom();
  const {state, t} = await import("../../apps/desktop/ui/state.js");
  const {promptSteamRestore} = await import("../../apps/desktop/ui/steam-restore.js");
  const {syncGameModsOnFocus} = await import("../../apps/desktop/ui/game-folder.js");
  const {setImmediate: flush} = await import("node:timers/promises");
  const calls = [];
  const path = "steam/copy";
  const dir = path + "/game";
  Object.assign(state, {game:path, inventory:{managed:"1"}, busyMod:""});
  window.__TAURI__.core.Channel = class {};
  let verification, progress, outcome;
  window.__TAURI__.core.invoke = async (command, args) => {
    calls.push(command);
    if (command === "steam_restore_dir") return dir;
    if (command === "game_process") {
      assert.deepEqual(args, {path, expectedDir:dir, action:"check"});
      return false;
    }
    if (command === "restore_steam_game") {
      assert.equal(args.path, path);
      assert.equal(args.expectedDir, dir);
      progress = args.progress;
      progress.onmessage("waiting");
      return verification.promise;
    }
    assert.equal(command, "cancel_steam_restore");
    if (outcome === "cancel") verification.reject("steamRestoreCancelled");
    return outcome === "cancel";
  };
  for (outcome of ["cancel", "lost race", "success"]) {
    verification = Promise.withResolvers();
    await promptSteamRestore();
    const confirm = body.children.at(-1).children.at(-1).onclick();
    await flush();
    assert.equal(body.children[0].textContent, t("steamRestoreWaiting"));
    await syncGameModsOnFocus();
    assert.deepEqual(calls.splice(0), ["steam_restore_dir","game_process","restore_steam_game"]);
    assert.deepEqual(state.inventory, {managed:"1"});
    if (outcome !== "success") await body.children.at(-1).children.at(-1).onclick();
    if (outcome !== "cancel") {
      assert.equal(dialog.open,true);
      progress.onmessage("cleaning");
      assert.equal(body.children.length,1);
      assert.equal(body.children[0].textContent,t("steamRestoreCleaning"));
      if (outcome === "lost race") verification.reject("fileWriteError");
      else verification.resolve({pckDir:dir, installed:{}, modStates:{}});
    }
    await confirm;
    assert.deepEqual(calls.splice(0), outcome === "success" ? [] : ["cancel_steam_restore"]);
    assert.equal(state.busyMod,"");
    if (outcome === "cancel") assert.equal(dialog.open,false);
    if (outcome === "lost race") {
      assert.equal(body.children[0].textContent,t("fileWriteError"));
      dialog.close();
    }
    if (outcome === "success") {
      assert.equal(body.children[0].textContent,t("steamRestoreDone"));
      assert.deepEqual(state.inventory,{});
    }
  }
});
