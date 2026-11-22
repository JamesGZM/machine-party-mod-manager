import { coverUrl, downloadUrl } from "./online-catalog.js";
import {
  BATCH_KINDS, batchAction, batchConfirmKey, batchEligible, batchEmptyKey, batchRunningKey,
  batchSelectAll, batchSelectedCount, batchSummary, batchTargets, batchToggle, canRunBatch
} from "./batch.js";
import { installationProblem, catalogAction, uninstallEntry } from "./mod-action.js";
import { clearPackage, downloadMod, installMod, verifyPackage, isDesktop, openProject, uninstallMod, updateMod } from "./bridge.js";
import { confirmGameExit } from "./game-exit-dialog.js";
import { inventoryKey, installedRows, releaseNotesFor, visibleMods } from "./catalog.js";
import { $, button, closeDialog, element, progress, show, tag } from "./dom.js";
import { applyValidation, syncGameMods, withGameCopy } from "./game-folder.js";
import { render, state, t } from "./state.js";
import { versionState } from "./versions.js";

const nameOf = mod => mod.name[state.locale];

const cached = mod => Boolean(mod.package && state.packages[mod.id] === mod.package.sha256);
const matchesMod = (item, mod) => item.id === mod.id && item.version === mod.version
  && item.package?.sha256 === mod.package?.sha256;
const pinnedOf = mod => state.pinned.find(item => matchesMod(item, mod));
const isPreview = mod => [...state.previewMods, ...(state.previewMod ? [state.previewMod] : [])].some(item => matchesMod(item, mod));
const support = mod => {
  const versions = mod.supportedGameVersions?.length ? mod.supportedGameVersions : pinnedOf(mod)?.supportedGameVersions;
  return versions?.length ? t("supportedGame") + " · " + versions.join(", ") : t("supportUnknown");
};
const trustedPackage = mod => isDesktop && Boolean(mod.package?.mirrorApproved) && Boolean(pinnedOf(mod));

const signedPackage = mod => isDesktop && state.updateTargets.some(item => matchesMod(item, mod));
const removalEntry = mod => uninstallEntry(mod.id, state.modStates[mod.id], [...state.pinned, ...state.removalMods, ...state.updateTargets]);
const approvedUpdate = mod => isDesktop && (signedPackage(mod)
  || (trustedPackage(mod) && (pinnedOf(mod).verified || isPreview(mod))));

function project(mod) {
  return button(mod.repo.split("/")[0], () => openProject(mod.repo), "link", "external");
}

function conflictingMods(mod) {
  const adapter = mod.adapter || pinnedOf(mod)?.adapter;
  if (!adapter) return [];
  return state.mods.filter(other => {
    if (state.modStates[other.id] === "legacyInstalled") return true;
    if (other.id === mod.id) return false;
    const isInstalled = state.modStates[other.id] === "installed" || state.inventory[inventoryKey(other)] !== undefined;
    if (!isInstalled) return false;
    const otherAdapter = other.adapter || pinnedOf(other)?.adapter;
    return adapter.exclusive === "pck" || !otherAdapter || otherAdapter.exclusive !== adapter.exclusive || Boolean(adapter.conflictGroup && adapter.conflictGroup === otherAdapter.conflictGroup);
  });
}

function conflictNames(mod) {
  const sep = state.locale === "en" ? ", " : "、";
  return conflictingMods(mod).map(nameOf).join(sep);
}

function details(mod) {
  const local = state.inventory[inventoryKey(mod)];
  const status = versionState(local, mod.version, mod.verified || approvedUpdate(mod));
  const modState = state.modStates[mod.id];
  const parts = [
    element("p", mod.detail[state.locale]),
    element("p", support(mod)),
    element("p", t("release") + " · " + (mod.version || t("unlisted")))
  ];
  if (local !== undefined) {
    parts.push(element("p", t("local") + " · " + local), element("p", t(status)));
    const bundled = state.pinned.find(item => item.id === mod.id);
    if (bundled && !pinnedOf(mod) && (bundled.adapter?.sourceRule || mod.adapter?.sourceRule)
        && versionState(bundled.version, mod.version, true) === "available")
      parts.push(element("p", t("updateManagerForMod")));
    else if (status === "waiting" || status === "newer")
      parts.push(element("p", t(status === "waiting" ? "hold" : "noDowngrade")));
  }
  if (modState === "installed" && currentAction(mod) === "updateMod") {
    parts.push(primaryAction(mod), button(t("uninstall"), () => uninstallDialog(mod), "secondary"));
  }
  if (modState === "needsRepair" && state.lastScan?.repair?.[mod.id] && removalEntry(mod)) parts.push(button(t("uninstall"), () => uninstallDialog(mod), "secondary"));
  if (modState === "legacyInstalled" && trustedPackage(mod) && (mod.verified || isPreview(mod))) parts.push(button(t("migrateLoader"), () => startInstall(mod, "switch"), "primary"));
  if (modState === "manualInstall") parts.push(element("p", t("manualDetected")));
  else if (modState === "gameUpdatedOrModified" || modState === "needsRepair")
    parts.push(element("p", t(modState), "error"));
  if (state.scan === "failed") parts.push(element("p", t(state.scanError) || t("statusUnavailable"), "error"));
  if (!mod.verified && !isPreview(mod) && !approvedUpdate(mod)) parts.push(element("p", t("installPending")));
  if (state.lastScan?.pckPath) parts.push(element("p", state.lastScan.pckPath, "file-detail"));
  const adapter = mod.adapter || pinnedOf(mod)?.adapter;
  const versions = mod.supportedGameVersions?.length ? mod.supportedGameVersions : pinnedOf(mod)?.supportedGameVersions;
  if (state.lastScan?.pckSha256 === adapter?.baseline?.sha256 && adapter && versions?.length === 1)
    parts.push(element("p", t("detectedVersion") + " · " + versions[0]));
  if (state.lastScan?.pckSha256) parts.push(element("p", "SHA-256 · " + state.lastScan.pckSha256, "file-detail"));
  const repair = state.lastScan?.repair?.[mod.id];
  if (repair) parts.push(element("p", t("backup") + " · " + repair[0], "file-detail"));
  if (repair?.[1]) {
    const [key, ...detail] = repair[1].split(": ");
    parts.push(element("p", [t(key) || key, ...detail].join(" · ")));
  }
  if (modState === "modConflict") {
    const names = conflictNames(mod);
    parts.push(element("p", names ? t("modConflictWith").replace("{mods}", names) : t("modConflict")));
  } else if (["manualBroadcastConflict", "restoreResidue", "identifyPending", "loaderConflict"].includes(modState)) {
    parts.push(element("p", t(modState)));
  }
  if (cached(mod)) parts.push(button(t("clearCache"), async () => {
    await clearPackage(mod);
    delete state.packages[mod.id];
    closeDialog();
    render();
  }));
  if (mod.package) {
    parts.push(element("p", mod.package.filename));
    if (mod.package.mirrorApproved) {
      const link = element("a", t("downloadPackage"), "btn btn-link");
      link.href = downloadUrl(mod);
      link.download = mod.package.filename;
      parts.push(link);
    }
  }
  parts.push(project(mod));
  show(nameOf(mod), ...parts);
}

function cover(mod, name) {
  const box = element("div", "", "cover");
  const fallback = element("strong", name, "cover-title");
  box.append(fallback);
  const src = coverUrl(mod);
  if (src) {
    const img = element("img", "", "loading");
    img.alt = "";
    img.decoding = "async";
    img.loading = "lazy";
    box.classList.add("skeleton");
    img.onload = () => { img.classList.remove("loading"); box.classList.remove("skeleton"); };
    img.onerror = () => { img.replaceWith(fallback); box.classList.remove("skeleton"); };
    img.src = src;
    fallback.replaceWith(img);
  }
  const tags = element("div", "", "cover-tags");
  const version = tag(mod.version || t("unlisted"));
  if (mod.version) version.classList.add("tag-mono");
  tags.append(version);
  const category = t("category_" + mod.category);
  if (category) tags.append(tag(category));
  box.append(tags);
  return box;
}

function confirmModUpdate(mod, revised = false) {
  const path = state.game;
  const dir = state.pckDir;
  const from = state.inventory[inventoryKey(mod)];
  const notes = releaseNotesFor(mod, state.locale);
  show(t("updateMod") + " · " + nameOf(mod),
    element("p", from + " → " + mod.version),
    ...(notes ? [
      element("strong", t(revised ? "modReleaseNotesChanged" : "modReleaseNotes")),
      element("p", notes, "release-notes")
    ] : []),
    button(t("cancelModUpdate"), closeDialog),
    button(t("confirmModUpdate"), () => {
      const latest = state.mods.find(item => item.id === mod.id);
      if (state.game !== path || state.pckDir !== dir || !latest || !matchesMod(latest, mod)
          || state.inventory[inventoryKey(latest)] !== from)
        return show(t("releaseChanged"), button(t("close"), closeDialog));
      const latestNotes = releaseNotesFor(latest, state.locale);
      if (latestNotes && latestNotes !== notes) return confirmModUpdate(latest, true);
      if (currentAction(latest) !== "updateMod")
        return show(t("releaseChanged"), button(t("close"), closeDialog));
      return installDialog(latest, "updateMod");
    }, "primary"));
}

function startInstall(mod, action) {
  return withGameCopy(() => {
    const migrate = action === "switch" && state.modStates[mod.id] === "legacyInstalled";
    if (!state.pckDir || (!migrate && currentAction(mod) !== action)) return details(mod);
    if (action === "updateMod") return confirmModUpdate(mod);
    if (action === "switch") {
      const removals = conflictingMods(mod);
      if (!removals.length) return details(mod);
      const path = state.game;
      const dir = state.pckDir;
      const names = removals.map(nameOf).join(state.locale === "en" ? ", " : "、");
      return show(nameOf(mod), element("p", t("switchNotice").replace("{mods}", names)),
        button(t("switch"), () => {
          if (state.game !== path || state.pckDir !== dir) return details(mod);
          return installDialog(mod, action, removals.map(item => item.id));
        }, "primary"));
    }
    return installDialog(mod, action);
  });
}

async function installDialog(mod, action, removals = []) {
  if (state.busyMod) return;
  const path = state.game;
  const target = state.pckDir;
  const from = state.inventory[inventoryKey(mod)];
  const title = key => t(key) + " · " + nameOf(mod) + " " + (action === "updateMod" ? from + " → " : "") + mod.version;
  const steps = element("ol", "", "install-steps");
  const lastStep = action === "identify" ? "identify"
    : action === "adoptManual" ? "adoptManual"
    : action === "switch" ? "switchStep"
    : action === "updateMod" ? "updateModStep" : "installStep";
  const stepKeys = ["downloadStep", "verifyStep", lastStep];
  const names = action === "switch" ? conflictNames(mod) : "";
  const notice = names ? element("p", t("switchNotice").replace("{mods}", names)) : null;
  const rows = stepKeys.map(key => {
    const row = element("li");
    const status = element("span");
    row.append(element("span", t(key)), status);
    steps.append(row);
    return status;
  });
  steps.setAttribute("aria-live", "polite");
  const bar = progress();
  const dialog = $("dialog");
  const close = $("#close");
  let stage = 0;
  const installStage = stepKeys.length - 1;
  const preventCancel = event => event.preventDefault();
  const controller = new AbortController();
  const ownsDialog = () => !controller.signal.aborted && dialog.open && steps.isConnected;
  const onClose = () => {
    if ((dialog.open && steps.isConnected) || close.disabled) return;
    dialog.removeEventListener("close", onClose);
    controller.abort();
    state.busyMod = "";
    render();
  };
  dialog.addEventListener("close", onClose);
  show(title(action), ...(notice ? [notice] : []), steps, bar.el);
  state.busyMod = mod.id;
  render();
  try {
    if (action !== "identify" && !await confirmGameExit(path, target, () => ownsDialog() && state.pckDir === target)) {
      if (ownsDialog()) closeDialog();
      return;
    }
    if (cached(mod)) {
      rows[0].textContent = t("usingCache");
    } else {
      rows[0].textContent = t("working");
      await downloadMod(mod, pct => { rows[0].textContent = pct + "%"; bar.set(pct); }, controller.signal);
      if (!ownsDialog()) return;
      state.packages[mod.id] = mod.package.sha256;
      rows[0].textContent = t("done");
    }
    if (!ownsDialog()) return;
    stage = 1;
    bar.el.hidden = true;
    rows[stage].textContent = t("working");
    await verifyPackage(mod);
    rows[stage].textContent = t("done");
    if (!ownsDialog()) return;
    stage = installStage;
    if (path !== state.game || target !== state.pckDir) throw "statusUnavailable";
    rows[stage].textContent = t("working");
    if (action !== "identify" && !await confirmGameExit(path, target, () => ownsDialog() && state.pckDir === target)) {
      if (ownsDialog()) closeDialog();
      return;
    }
    close.disabled = true;
    dialog.addEventListener("cancel", preventCancel);
    if (action === "identify") {
      await syncGameMods(true);
      if (state.scan !== "ready") throw state.scanError || "statusUnavailable";
      rows[stage].textContent = t("disk_" + state.modStates[mod.id]);
      if (state.modStates[mod.id] === "manualInstall") {
        show(title("identifySuccess"), steps, button(t("adoptManual"), () => startInstall(mod, "adoptManual"), "primary"));
        return;
      }
    } else {
      const result = action === "updateMod" ? await updateMod(path, mod, from, target)
        : await installMod(path, mod, action === "adoptManual", target, removals);
      applyValidation(result, path);
      const problem = installationProblem(result, mod);
      if (problem) throw problem;
      rows[stage].textContent = t("done");
    }
    show(title(action + "Success"), steps);
  } catch (error) {
    if (!ownsDialog()) return;
    const [key, ...detail] = String(error).split(": ");
    if (["downloadFirst", "packageCorrupt"].includes(key)) delete state.packages[mod.id];
    if (action === "updateMod" && key === "modUpdatedRescan") {
      rows[stage].textContent = t("done");
      show(title("updateModSuccess"), steps, element("p", t(key)));
      if (state.game === path) await syncGameMods(true);
      return;
    }
    rows[stage].textContent = t("failed");
    let retryButton;
    if (ownsDialog()) {
      const message = element("p", [t(key) || key, ...detail].join(" · "), "error");
      const retry = ["downloadFailed", "packageCorrupt", "downloadFirst", "gameRunning", "gamePermissionDenied", "diskSpace"].includes(key);
      if (retry) {
        retryButton = button(t("retry"), () => startInstall(mod, action), "primary");
        retryButton.disabled = true;
      }
      show(title(action + "Failure"), message, steps, ...(retryButton ? [retryButton] : []));
    }
    if (stage === installStage && path && path === state.game) await syncGameMods(true);
    if (retryButton) retryButton.disabled = false;
  } finally {
    dialog.removeEventListener("close", onClose);
    dialog.removeEventListener("cancel", preventCancel);
    if (!controller.signal.aborted) {
      close.disabled = false;
      state.busyMod = "";
      render();
    }
  }
}

function currentAction(mod) {
  return catalogAction({
    page:state.page, disk:state.modStates[mod.id], scan:state.scan, game:state.game,
    installed:removalEntry(mod), approved:approvedUpdate(mod), bundled:trustedPackage(mod),
    local:state.inventory[inventoryKey(mod)], version:mod.version
  });
}

function uninstallDialog(cardMod) {
  const mod = removalEntry(cardMod);
  if (!mod) return details(cardMod);
  const path = state.game;
  const target = state.pckDir;
  const name = nameOf(cardMod);
  const installedVersion = state.inventory[inventoryKey(mod)];
  const title = key => t(key) + " · " + name + (installedVersion ? " " + installedVersion : "");
  const steps = element("ol", "", "install-steps");
  const row = element("li");
  const status = element("span");
  row.append(element("span", t("restoreStep")), status);
  steps.append(row);
  steps.setAttribute("aria-live", "polite");
  const dialog = $("dialog");
  const close = $("#close");
  const preventCancel = event => event.preventDefault();

  const run = async () => {
    if (state.busyMod || path !== state.game || target !== state.pckDir) return;
    state.busyMod = mod.id;
    status.textContent = t("working");
    close.disabled = true;
    dialog.addEventListener("cancel", preventCancel);
    show(title("uninstall"), steps);
    render();
    try {
      if (!await confirmGameExit(path, target, () => dialog.open && steps.isConnected && state.pckDir === target)) {
        closeDialog();
        return;
      }
      const result = await uninstallMod(path, mod, target);
      applyValidation(result, path);
      if (result.modStates[mod.id] !== "vanilla") {
        throw result.modStates[mod.id] || "uninstallFailed";
      }
      status.textContent = t("done");
      show(title("uninstallSuccess"), steps);
    } catch (error) {
      status.textContent = t("failed");
      const [key, ...detail] = String(error).split(": ");
      const message = element("p", [t(key) || key, ...detail].join(" · "), "error");
      const retry = ["gameRunning", "gamePermissionDenied", "diskSpace"].includes(key);
      let retryButton;
      if (retry) {
        retryButton = button(t("retry"), run, "primary");
        retryButton.disabled = true;
      }
      show(title("uninstallFailure"), message, steps, ...(retryButton ? [retryButton] : []));
      if (state.game === path) await syncGameMods(true);
      if (retryButton) retryButton.disabled = false;
    } finally {
      dialog.removeEventListener("cancel", preventCancel);
      close.disabled = false;
      state.busyMod = "";
      render();
    }
  };

  show(title("uninstall"), steps, button(t("uninstall"), run, "primary"));
}

function primaryAction(mod) {
  const action = currentAction(mod);
  const label = action === "updateMod" ? t("updateModTo").replace("{version}", mod.version) : t(action === "review" ? "viewReason" : action);
  const el = button(label, () => {
    if (action === "review") return details(mod);
    if (action === "retryCheck") return withGameCopy(undefined, true);
    if (action !== "uninstall") return startInstall(mod, action);
    return withGameCopy(() => currentAction(mod) === "uninstall" ? uninstallDialog(mod) : details(mod));
  }, ["review", "uninstall", "checking"].includes(action) ? "secondary" : "primary");
  el.disabled = Boolean(state.busyMod) || action === "checking";
  el.classList.add("btn-block");
  return el;
}

function card(mod, index) {
  const name = nameOf(mod);
  const local = state.inventory[inventoryKey(mod)];
  const item = element("article", "", "card");
  item.style.setProperty("--i", String(index));

  const body = element("div", "", "card-body");
  const heading = element("h2", "", "card-title");
  const link = element("a", name);
  link.href = "#" + encodeURIComponent(inventoryKey(mod));
  link.onclick = event => { event.preventDefault(); details(mod); };
  heading.append(link);
  body.append(heading, element("p", mod.summary[state.locale], "card-summary"));
  body.append(element("p", support(mod), "panel-note"));
  if (local !== undefined) {
    const versions = element("div", "", "comparison");
    versions.append(
      element("span", t("local") + " · " + local),
      element("span", t("release") + " · " + (mod.version || t("unlisted")))
    );
    body.append(versions);
  }

  const footer = element("div", "", "card-actions");
  footer.append(primaryAction(mod));
  const coverBox = cover(mod, name);
  // Selection lives in state.selectedMods keyed by mod id, so every catalog
  // card is tickable at all times - the user picks cards first, then chooses
  // an operation from the top menu. Search/sort/filter never loses a tick.
  if (state.page === "catalog") {
    item.classList.toggle("batch-selected", state.selectedMods.includes(mod.id));
    coverBox.append(batchCheckbox(mod));
  }
  item.append(coverBox, body, footer);
  return item;
}

// ---- Batch operations -------------------------------------------------
// The batch flow reuses the single-mod commands; the only new logic is the
// persistent card selection and a serial driver that rechecks each row before
// touching disk. Nothing outside the user's ticked cards is ever executed.
const BATCH_BUSY = "__batch__";

const batchRow = mod => ({
  ready: Boolean(state.game) && state.scan === "ready",
  action: currentAction(mod),
  removable: Boolean(removalEntry(mod))
});

// Menu badges count the intersection of the live selection with each
// operation's condition - never the whole catalog.
export function batchCounts() {
  return BATCH_KINDS.map(kind => ({
    kind,
    count: batchSelectedCount(state.mods, kind, batchRow, state.selectedMods)
  }));
}

// Badges are refreshed in place: a full render would drop the focus of the
// checkbox / search box the user is interacting with.
export function refreshMenuCounts() {
  for (const {kind, count} of batchCounts()) {
    const counter = $("#ops-count-" + kind);
    if (counter) counter.textContent = String(count);
    const item = document.querySelector('.ops-item[data-kind="' + kind + '"]');
    if (item) item.classList.toggle("ops-empty", count === 0);
  }
}

let selectionBarRefs = null;

function syncSelectionBar() {
  if (!selectionBarRefs || !selectionBarRefs.bar.isConnected) {
    selectionBarRefs = null;
    return;
  }
  const {count, all, clear} = selectionBarRefs;
  const running = state.batch?.phase === "running";
  count.textContent = t("batchSelected").replace("{count}", String(state.selectedMods.length));
  all.disabled = running;
  clear.disabled = running || !state.selectedMods.length;
}

function selectionBarButton(text, action, variant, disabled) {
  const el = element("button", text, "btn btn-" + variant);
  el.type = "button";
  el.disabled = disabled;
  el.onclick = action;
  return el;
}

// Every catalog card gets a checkbox. Tick state is stored by mod id, so it
// survives sorting, search filtering and page switches.
function batchCheckbox(mod) {
  const label = element("label", "", "batch-check");
  label.setAttribute("aria-label", t("batchSelectMod").replace("{mod}", nameOf(mod)));
  label.title = nameOf(mod);
  const input = document.createElement("input");
  input.type = "checkbox";
  input.checked = state.selectedMods.includes(mod.id);
  input.disabled = state.batch?.phase === "running";
  input.onchange = () => {
    if (state.batch?.phase === "running") return;
    state.selectedMods = batchToggle(state.selectedMods, mod.id, input.checked);
    label.closest(".card")?.classList.toggle("batch-selected", input.checked);
    syncSelectionBar();
    refreshMenuCounts();
  };
  label.append(input, element("span", "", "batch-check-box"));
  return label;
}

// A light, always-present selection strip. Execution itself is triggered from
// the top menu, so there is no second "run" entry point.
function renderSelectionBar(content) {
  const running = state.batch?.phase === "running";
  const bar = element("section", "", "batch-bar");
  bar.setAttribute("role", "region");
  bar.setAttribute("aria-label", t("batchActions"));
  const info = element("div", "", "batch-info");
  info.append(
    element("strong", t("batchActions")),
    element("p", t("batchSelectHint"))
  );
  const count = element("span", "", "batch-count");
  const actions = element("div", "", "batch-actions");
  const all = selectionBarButton(t("batchSelectAll"), () => {
    const visible = visibleMods(state.mods, {query: $("#search input").value}).map(mod => mod.id);
    state.selectedMods = batchSelectAll(state.selectedMods, visible);
    render();
  }, "secondary", running);
  const clear = selectionBarButton(t("batchClear"), () => {
    state.selectedMods = [];
    render();
  }, "ghost", running || !state.selectedMods.length);
  actions.append(all, clear);
  bar.append(info, count, actions);
  content.append(bar);
  selectionBarRefs = {bar, count, all, clear};
  syncSelectionBar();
}

function batchNotify(text) {
  show(t("batchActions"), element("p", text), button(t("close"), closeDialog, "primary"));
}

// A menu item always acts on the current ticked cards. Cards that no longer
// match the operation are filtered out and reported in the confirmation.
function runFromMenu(kind) {
  if (!BATCH_KINDS.includes(kind) || state.batch?.phase === "running") return;
  if (!state.selectedMods.length) return batchNotify(t("batchNeedSelection"));
  if (!state.game) return batchNotify(t("batchNeedGame"));
  if (state.scan !== "ready") return batchNotify(t("batchScanning"));
  const {queue, filtered} = batchTargets(state.mods, kind, batchRow, state.selectedMods);
  if (!canRunBatch(queue)) return batchNotify(t(batchEmptyKey(kind)));
  confirmBatchRun(kind, queue, filtered);
}

// Explicit confirmation before any write - uninstall uses a deliberately
// stronger wording because it restores original game files.
function confirmBatchRun(kind, queue, filtered) {
  const list = element("ul", "", "batch-confirm-list");
  for (const id of queue) {
    const mod = state.mods.find(item => item.id === id);
    list.append(element("li", mod ? nameOf(mod) : id));
  }
  const note = filtered.length
    ? element("p", t("batchFilteredHint").replace("{count}", String(filtered.length)), "panel-note")
    : element("p", t("batchConfirmHint"), "panel-note");
  show(t(batchConfirmKey(kind)).replace("{count}", String(queue.length)),
    list, note,
    button(t("batchCancel"), closeDialog, "secondary"),
    button(t("batchConfirm"), () => startBatch(kind, queue), "primary"));
}

export function setupBatchMenu() {
  const ops = $("#batch-ops");
  const toggle = $("#batch-toggle");
  const menu = $("#batch-menu");
  let hoverTimer = 0;
  let leaveTimer = 0;
  let hoverOpened = false;

  const isOpen = () => ops.classList.contains("open");
  const setOpen = open => {
    ops.classList.toggle("open", open);
    toggle.setAttribute("aria-expanded", String(open));
  };

  // Button and menu are siblings inside the same .ops container, and a
  // transparent ::before on the menu bridges the 8px gap. Moving the pointer
  // from the button into the menu therefore never leaves .ops. The short
  // delay plus a :hover recheck also guards against out-of-order mouseleave.
  ops.addEventListener("mouseenter", () => {
    window.clearTimeout(leaveTimer);
    if (toggle.disabled || isOpen()) return;
    hoverTimer = window.setTimeout(() => {
      if (toggle.disabled || isOpen() || !ops.matches(":hover")) return;
      hoverOpened = true;
      setOpen(true);
    }, 60);
  });
  ops.addEventListener("mouseleave", () => {
    window.clearTimeout(hoverTimer);
    leaveTimer = window.setTimeout(() => {
      if (!ops.matches(":hover")) {
        hoverOpened = false;
        setOpen(false);
      }
    }, 140);
  });
  toggle.addEventListener("click", () => {
    if (toggle.disabled) return;
    window.clearTimeout(hoverTimer);
    window.clearTimeout(leaveTimer);
    // Hover may already have opened the menu. In that case a click confirms
    // the open state instead of toggling it shut; a further click closes it.
    if (isOpen() && hoverOpened) {
      hoverOpened = false;
      return;
    }
    hoverOpened = false;
    setOpen(!isOpen());
  });
  document.addEventListener("click", event => {
    if (!ops.contains(event.target)) {
      hoverOpened = false;
      setOpen(false);
    }
  });
  document.addEventListener("keydown", event => {
    if (event.key === "Escape") {
      hoverOpened = false;
      setOpen(false);
    }
  });
  for (const item of menu.querySelectorAll(".ops-item")) {
    item.addEventListener("click", () => {
      if (state.batch?.phase === "running") return;
      hoverOpened = false;
      window.clearTimeout(leaveTimer);
      setOpen(false);
      runFromMenu(item.dataset.kind);
    });
  }
}

async function rescanBatch(path) {
  if (state.game !== path) return;
  try { await syncGameMods(true); } catch { /* scan failures are surfaced by the next recheck */ }
}

// Executes one selected mod. Returns "ok", "skip" or "abort"; throws on failure.
async function executeBatchItem(kind, id, path, onProgress, signal, owns) {
  const mod = state.mods.find(item => item.id === id);
  if (!mod || !batchEligible(kind, batchRow(mod))) return "skip";
  if (state.game !== path || !state.pckDir) return "abort";
  const dir = state.pckDir;
  if (!await confirmGameExit(path, dir, () => owns() && state.pckDir === dir)) return "abort";
  if (!owns()) return "abort";
  const latest = state.mods.find(item => item.id === id) || mod;
  const action = batchAction(kind);
  if (action === "uninstall") {
    const entry = removalEntry(latest);
    if (!entry) return "skip";
    const result = await uninstallMod(path, entry, dir);
    applyValidation(result, path);
    if (result.modStates[entry.id] !== "vanilla") throw result.modStates[entry.id] || "uninstallFailed";
    return "ok";
  }
  if (cached(latest)) {
    onProgress(t("usingCache"));
  } else {
    onProgress(t("working"));
    await downloadMod(latest, pct => onProgress(pct + "%"), signal);
    if (!owns()) return "abort";
    state.packages[latest.id] = latest.package.sha256;
  }
  if (!owns()) return "abort";
  await verifyPackage(latest);
  if (!owns()) return "abort";
  const from = state.inventory[inventoryKey(latest)];
  let result;
  try {
    result = action === "updateMod"
      ? await updateMod(path, latest, from, dir)
      : await installMod(path, latest, false, dir, []);
  } catch (error) {
    // The new version is on disk; only the follow-up rescan failed.
    if (action === "updateMod" && String(error).startsWith("modUpdatedRescan")) {
      await rescanBatch(path);
      return "ok";
    }
    throw error;
  }
  applyValidation(result, path);
  const problem = installationProblem(result, latest);
  if (problem) throw problem;
  return "ok";
}

function startBatch(kind, queue) {
  // Guard against a double submit from the confirmation dialog.
  if (state.batch?.phase === "running") return;
  const batch = {kind, phase: "running", ids: queue.slice()};
  state.batch = batch;
  state.busyMod = BATCH_BUSY;
  render();
  // A driver-level failure must never leave the UI stuck in "running".
  void runBatchDialog(batch, queue).catch(error => {
    console.error("batch operation failed", error);
    const dialog = $("dialog");
    $("#close").disabled = false;
    if (dialog.open) {
      show(t("failed"), element("p", String(error), "error"),
        button(t("batchConfirm"), closeDialog, "primary"));
    } else {
      state.busyMod = "";
      state.batch = null;
      render();
    }
  });
}

async function runBatchDialog(batch, queue) {
  const kind = batch.kind;
  const path = state.game;
  const dialog = $("dialog");
  const close = $("#close");
  const controller = new AbortController();
  const preventCancel = event => event.preventDefault();

  const list = element("ol", "", "install-steps batch-steps");
  list.setAttribute("aria-live", "polite");
  const bar = progress();
  const rows = new Map();
  for (const id of queue) {
    const mod = state.mods.find(item => item.id === id);
    const li = element("li");
    const status = element("span", t("batchItemPending"));
    li.append(element("span", mod ? nameOf(mod) : id), status);
    list.append(li);
    rows.set(id, {li, status});
  }
  const owns = () => !controller.signal.aborted && dialog.open && list.isConnected;
  const setStatus = (id, text, tone) => {
    const row = rows.get(id);
    if (!row) return;
    row.status.textContent = text;
    row.li.classList.remove("batch-ok", "batch-fail", "batch-skip");
    if (tone) row.li.classList.add("batch-" + tone);
  };
  const onClose = () => {
    dialog.removeEventListener("close", onClose);
    dialog.removeEventListener("cancel", preventCancel);
    controller.abort();
    close.disabled = false;
    state.busyMod = "";
    state.batch = null;
    selectionBarRefs = null;
    render();
  };
  dialog.addEventListener("close", onClose);
  dialog.addEventListener("cancel", preventCancel);
  close.disabled = true;
  show(t(batchRunningKey(kind)), element("p", t("batchWorkingHint")), list, bar.el);

  const results = [];
  let aborted = false;
  let completed = 0;
  for (const id of queue) {
    if (!owns()) return;
    setStatus(id, t("working"));
    let outcome;
    try {
      outcome = await executeBatchItem(kind, id, path, pct => setStatus(id, pct), controller.signal, owns);
    } catch (error) {
      outcome = "fail";
      const [key, ...detail] = String(error).split(": ");
      if (["downloadFirst", "packageCorrupt", "downloadFailed"].includes(key)) delete state.packages[id];
      setStatus(id, [t(key) || key, ...detail].join(" · "), "fail");
    }
    if (!owns()) return;
    if (outcome === "abort") {
      setStatus(id, t("batchItemSkipped"), "skip");
      results.push("skip");
      aborted = true;
      break;
    }
    if (outcome === "ok") setStatus(id, t("done"), "ok");
    else if (outcome === "skip") setStatus(id, t("batchItemSkipped"), "skip");
    results.push(outcome);
    completed++;
    bar.set(Math.round(completed / queue.length * 100));
    if (outcome !== "ok") await rescanBatch(path);
  }
  if (!owns()) return;
  batch.phase = "done";
  bar.set(100);
  // Successful mods are no longer eligible, so drop their ticks. Failed and
  // skipped ones stay selected to make a retry a single click.
  const okIds = new Set(queue.filter((id, index) => results[index] === "ok"));
  state.selectedMods = state.selectedMods.filter(id => !okIds.has(id));
  render();
  const summary = batchSummary(results);
  const text = t("batchSummary")
    .replace("{ok}", String(summary.ok))
    .replace("{fail}", String(summary.fail))
    .replace("{skip}", String(summary.skip));
  dialog.removeEventListener("cancel", preventCancel);
  close.disabled = false;
  show(aborted ? t("batchAborted") : t("batchDone"),
    element("p", text, "batch-summary"), list, bar.el,
    button(t("batchConfirm"), closeDialog, "primary"));
}

export function renderModList(content) {
  if (state.page === "catalog") renderSelectionBar(content);
  if (state.scan === "failed") content.append(button(t("retryCheck"), () => withGameCopy(undefined, true), "secondary", "refresh"));
  const cards = state.page === "installed"
    ? installedRows(state.inventory, state.mods, [...state.removalMods, ...state.pinned]).map(({repo, version, mod}, index) => {
      if (mod) return card(mod, index);
      const row = element("article", "", "card");
      const body = element("div", "", "card-body");
      body.append(element("h2", repo, "card-title"), element("p", t("local") + " · " + version));
      row.append(body);
      return row;
    })
    : visibleMods(state.mods, {query:$("#search input").value}).map(card);
  if (cards.length) {
    const grid = element("div", "", "grid");
    grid.append(...cards);
    content.append(grid);
  } else if (state.page === "installed" && state.scan === "checking") {
    content.append(element("p", t("checking"), "empty"));
  } else if (state.scan !== "failed" || state.page === "catalog") {
    content.append(element("p", t(state.page === "installed" ? "noMods" : "noMatch"), "empty"));
  }
}
