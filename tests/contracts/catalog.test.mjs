import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import test from "node:test";
import { installedRows, releaseNotesFor, sortMods, visibleMods } from "../../apps/desktop/ui/catalog.js";
import { locales, messages } from "../../apps/desktop/ui/languages.js";
import { listFirstPartyMods, packMod } from "../../scripts/pack-mod.mjs";

const catalog = JSON.parse(await readFile(new URL("../../catalog/mods.json", import.meta.url), "utf8"));

test("every catalog entry has a stable identity and complete translations", () => {
  assert.equal(catalog.schema, 1);
  const unique = key => new Set(catalog.mods.map(mod => mod[key])).size === catalog.mods.length;
  assert.ok(unique("id") && unique("order") && new Set(catalog.mods.map(m => m.inventoryById ? m.id : m.repo)).size === catalog.mods.length);
  for (const mod of catalog.mods) {
    assert.match(mod.id, /^[a-z0-9-]+$/);
    assert.match(mod.repo, /^[\w.-]+\/[\w.-]+$/);
    assert.ok(Number.isInteger(mod.order) && mod.order > 0);
    assert.ok(["expansion", "game", "tool", "graphics"].includes(mod.category), mod.id);
    assert.equal(messages["category_" + mod.category].filter(Boolean).length, locales.length);
    assert.equal(typeof mod.verified, "boolean");
    assert.ok(Array.isArray(mod.aliases));
    if (mod.releaseNotes != null) {
      assert.equal(mod.releaseNotes.version, mod.version);
      for (const locale of locales) {
        if (locale in mod.releaseNotes) assert.equal(typeof mod.releaseNotes[locale], "string", mod.id + " " + locale);
      }
    }
    for (const field of ["name", "summary", "detail"])
      assert.deepEqual(Object.keys(mod[field]).sort(), [...locales].sort(), `${mod.id}.${field}`);
  }
});

test("update notes come from the selected release and locale", () => {
  const mod = {version: "v2", releaseNotes: {version: "v2", en: "Changes", "zh-TW": "更新內容"}};
  assert.equal(releaseNotesFor(mod, "zh-TW"), "更新內容");
  assert.equal(releaseNotesFor(mod, "zh-CN"), "");
  assert.equal(releaseNotesFor({...mod, version: "v3"}, "en"), "");
  assert.equal(releaseNotesFor({version: "v1"}, "en"), "");
});

test("optional mod covers live in catalog/covers with matching hashes and never bundle into the UI", async () => {
  const uiImages = (await readdir(new URL("../../apps/desktop/ui/images", import.meta.url))).sort();
  assert.deepEqual(uiImages, ["logo.svg"], "desktop UI must not bundle mod cover images");
  const exts = {"image/png": /\.png$/i, "image/webp": /\.webp$/i, "image/jpeg": /\.jpe?g$/i};
  for (const mod of catalog.mods) {
    assert.equal(mod.image, undefined, `${mod.id}: use optional R2 cover instead of built-in image`);
    if (!mod.cover) continue;
    assert.match(mod.cover.filename, /^[a-z0-9-]+\.(?:png|webp|jpe?g)$/i, mod.id);
    assert.ok(mod.cover.contentType in exts, `${mod.id}: unsupported cover contentType`);
    assert.match(mod.cover.filename, exts[mod.cover.contentType], `${mod.id}: cover extension mismatch`);
    const bytes = await readFile(new URL(`../../catalog/covers/${mod.cover.filename}`, import.meta.url));
    assert.ok(bytes.length > 0 && bytes.length <= 4 * 1024 * 1024, `${mod.id}: cover exceeds 4 MiB budget`);
    assert.equal(bytes.length, mod.cover.size, `${mod.id}: cover size mismatch`);
    assert.equal(createHash("sha256").update(bytes).digest("hex"), mod.cover.sha256, `${mod.id}: cover sha256 mismatch`);
  }
});

test("search matches partial translated titles only and preserves catalog order", () => {
  const mods = sortMods(catalog);
  const ids = query => visibleMods(mods, {query}).map(mod => mod.id);
  assert.deepEqual(ids("  "), mods.filter(mod => mod.role !== "library").map(mod => mod.id));
  assert.deepEqual(ids("  ErTiM  "), ["overtime"]);
  assert.deepEqual(ids("滚筒"), ["roller-carnival"]);
  assert.deepEqual(ids("嘉年華"), ["roller-carnival"]);
  assert.deepEqual(ids("er"), mods.filter(mod => ["overtime", "binary1936-8p", "roller-carnival", "player-spotlight"].includes(mod.id)).map(mod => mod.id));
  for (const query of ["mpml", "darkjadestone", "直播", "nothing-matches"]) assert.deepEqual(ids(query), []);
});

test("search ignores extra fields in a remote title", () => {
  const [entry] = catalog.mods;
  const mod = {...entry, name: {...entry.name, ja: null, de: "Überstunden"}};
  assert.deepEqual(visibleMods([mod], {query: "über"}), []);
  assert.deepEqual(visibleMods([mod], {query: "overtime"}), [mod]);
});

test("the installed page lists only mods recorded for the selected copy", () => {
  const mods = sortMods(catalog);
  const inventory = {"Ghostx10742/MachineParty-Plus": "v2.0.0"};
  for (const online of [mods, [], mods.filter(mod => mod.id !== "machineparty-plus")]) {
    const rows = installedRows(inventory, online, mods);
    assert.deepEqual(rows.map(row => [row.mod.id, row.version]), [["machineparty-plus", "v2.0.0"]]);
  }
  assert.deepEqual(installedRows({"retired/project":"v1"}, [], mods),
    [{repo:"retired/project", version:"v1", mod:undefined}]);
});

test("every catalog mod declares a valid Windows adapter profile", () => {
  assert.equal(catalog.repo, "JamesGZM/machine-party-mod-manager");
  for (const mod of catalog.mods) {
    assert.equal(mod.windowsPreview, "0.2.6-1", mod.id);
    assert.deepEqual(mod.adapter.platforms, ["windows"], mod.id);
    assert.equal(mod.adapter.target, "pckDir", mod.id);
    assert.ok(mod.adapter.exclusive, mod.id);
    if (mod.adapter.kind === "upstream-cli") {
      assert.ok(mod.adapter.forbiddenArgs.includes("--force"), mod.id);
      assert.ok(!mod.adapter.run.common.includes("--force"), mod.id);
      assert.ok(!mod.adapter.actions.install.includes("--force"), mod.id);
    } else {
      assert.equal(mod.adapter.kind, "loader-files", mod.id);
      assert.deepEqual(mod.adapter.touches, ["mods"], mod.id);
    }
  }
  const overtime = catalog.mods.find(mod => mod.id === "overtime");
  assert.equal(overtime.package.assetId, "594522625");
  assert.equal(overtime.package.filename, "Machine-Party-Overtime-1.7-CLI.zip");
  assert.equal(overtime.adapter.kind, "loader-files");
  assert.equal(overtime.adapter.exclusive, "loader");
  assert.equal(overtime.adapter.autoLoader, true);

  const plus = catalog.mods.find(mod => mod.id === "machineparty-plus");
  assert.equal(plus.adapter.kind, "loader-files");
  assert.equal(plus.adapter.exclusive, "loader");
  assert.equal(plus.adapter.autoLoader, true);

  const roller = catalog.mods.find(mod => mod.id === "roller-carnival");
  assert.equal(roller.package.filename, "roller-carnival-0.1.13.zip");
  assert.equal(roller.package.mirrorApproved, true);
  assert.equal(roller.adapter.kind, "loader-files");
  assert.equal(roller.adapter.autoLoader, true);

  const bubble = catalog.mods.find(mod => mod.id === "bubble-blitz");
  assert.equal(bubble.package.filename, "bubble-blitz-0.1.7.zip");
  assert.equal(bubble.package.mirrorApproved, true);
  assert.equal(bubble.adapter.kind, "loader-files");
  assert.equal(bubble.adapter.autoLoader, true);
});

test("every mod under mods/ has matching manifest, README and deterministic ZIP package", async () => {
  for (const id of await listFirstPartyMods()) {
    const mod = catalog.mods.find(item => item.id === id);
    assert.ok(mod, `catalog/mods.json missing entry for mods/${id}`);
    const manifestUrl = new URL(`../../mods/${id}/mod.json`, import.meta.url);
    const manifest = JSON.parse(await readFile(manifestUrl, "utf8"));
    assert.equal(manifest.id, mod.id, `${mod.id}: mod.json id mismatch`);
    assert.equal(`v${manifest.version}`, mod.version, `${mod.id}: mod.json version mismatch`);
    assert.equal(typeof manifest.entry, "string", `${mod.id}: mod.json entry missing`);
    assert.ok(manifest.entry.length > 0, `${mod.id}: mod.json entry empty`);
    await readFile(new URL(`../../mods/${id}/${manifest.entry}`, import.meta.url), "utf8");

    const readme = await readFile(new URL(`../../mods/${id}/README.md`, import.meta.url), "utf8");
    assert.ok(readme.trim().length > 0, `${mod.id}: README.md must not be empty`);

    const packed = await packMod(id);
    assert.equal(packed.filename, mod.package.filename, `${mod.id}: ZIP filename mismatch`);
    assert.equal(packed.size, mod.package.size, `${mod.id}: ZIP size mismatch`);
    assert.equal(packed.sha256, mod.package.sha256, `${mod.id}: ZIP sha256 mismatch`);
    assert.deepEqual([...mod.adapter.requiredFiles].sort(), [...packed.files].sort(), `${mod.id}: requiredFiles mismatch`);
  }
});

test("the preview displays exactly the remotely supplied catalog rows and metadata", () => {
  const preview = catalog.mods.find(mod => mod.windowsPreview === "0.2.6-1");
  const live = {...preview, name:{...preview.name,en:"Updated online"}};
  assert.equal(sortMods({mods:[live]})[0], live);
  assert.deepEqual(sortMods({mods:[]}), []);
});

test("first-party mods sharing a repository have independent installed versions", () => {
  const roller = catalog.mods.find(mod => mod.id === "roller-carnival");
  const bot = catalog.mods.find(mod => mod.id === "lobby-bots");
  assert.equal(roller.repo, bot.repo);
  const both = {[roller.id]: roller.version, [bot.id]: bot.version};
  assert.deepEqual(installedRows(both, catalog.mods, []).map(row => [row.mod.id, row.version]),
    [[roller.id, roller.version], [bot.id, bot.version]]);
  const cached = {...roller};
  delete cached.legacyInventoryRepos;
  const rows = installedRows(both, sortMods({mods:[cached, bot]}, catalog.mods), catalog.mods);
  assert.deepEqual(rows.map(row => row.mod.id), [roller.id, bot.id]);
  delete both[bot.id];
  assert.deepEqual(installedRows(both, [], catalog.mods).map(row => row.mod.id), [roller.id]);
});
