import { checkApp } from "./app-update.js";
import { authorizeUpdates, appVersion, bundledCatalog, cachedPackages, isDesktop, setAppTitle } from "./bridge.js";
import { sortMods } from "./catalog.js";
import { refreshMenuCounts, renderModList, setupBatchMenu } from "./catalog-view.js";
import { $, button, closeDialog, element, hydrateIcons, show } from "./dom.js";
import { detectGame, pickGame, syncGameMods, syncGameModsOnFocus } from "./game-folder.js";
import { icon } from "./icons.js";
import { renderSettings } from "./settings-view.js";
import { onRender, state, t } from "./state.js";

import { loadCatalog, restoreCatalog } from "./online-catalog.js";

let catalogStatus = "catalogLoading";
let catalogError = "";
let shownPage = "";

function applyLocale() {
  document.documentElement.lang = state.locale;
  document.title = "Machine Party " + t("manager");
  setAppTitle(document.title);
  $(".brand").setAttribute("aria-label", document.title);
  $(".brand small").textContent = t("manager");
  $("#search input").placeholder = t("search");
  $("#search input").setAttribute("aria-label", t("search"));
  const refresh = $("#refresh-catalog");
  refresh.title = t("refreshCatalog");
  refresh.setAttribute("aria-label", refresh.title);
  $("#close").setAttribute("aria-label", t("close"));
  for (const el of document.querySelectorAll("[data-i18n]")) el.textContent = t(el.dataset.i18n);
  $("#batch-menu").setAttribute("aria-label", t("batchActions"));
  $("#batch-toggle").setAttribute("aria-label", t("batchActions"));
  for (const el of document.querySelectorAll("[data-page]")) {
    el.title = t(el.dataset.page);
    el.setAttribute("aria-label", el.title);
    el.querySelector(".nav-label").textContent = el.title;
  }
}

function render() {
  document.querySelectorAll("[data-page]").forEach(el => {
    const active = el.dataset.page === state.page;
    el.classList.toggle("active", active);
    if (active) el.setAttribute("aria-current", "page");
    else el.removeAttribute("aria-current");
  });
  const settingsNav = document.querySelector('[data-page="settings"]');
  const existingDot = settingsNav?.querySelector(".update-dot");
  if (state.release && settingsNav && !existingDot) {
    const dot = element("span", "", "update-dot");
    dot.setAttribute("aria-hidden", "true");
    settingsNav.append(dot);
  } else if (!state.release && existingDot) {
    existingDot.remove();
  }
  $("h1").textContent = t(state.page);
  $("#subtitle").textContent = state.page === "settings" ? "" : t(state.page + "Sub");
  $("#search").hidden = state.page !== "catalog";
  const refresh = $("#refresh-catalog");
  const loading = catalogStatus === "catalogLoading";
  refresh.hidden = state.page !== "catalog";
  refresh.disabled = loading || Boolean(state.busyMod);
  refresh.setAttribute("aria-busy", String(loading));
  const ops = $("#batch-ops");
  const busyBatch = state.batch?.phase === "running";
  ops.hidden = state.page !== "catalog";
  const toggle = $("#batch-toggle");
  toggle.disabled = busyBatch || loading;
  $("#search input").disabled = busyBatch;
  if (busyBatch) {
    ops.classList.remove("open");
    toggle.setAttribute("aria-expanded", "false");
  }
  if (!ops.hidden) refreshMenuCounts();
  const content = $("#content");
  content.replaceChildren();
  content.className = state.page === shownPage ? "" : "entering";
  shownPage = state.page;
  if (state.page === "settings") renderSettings(content, applyLocale);
  else {
    if (catalogStatus) {
      const status = element("section", "", "list-status" + (state.mods.length ? " compact" : ""));
      status.setAttribute("role", "status");
      status.append(icon(catalogStatus === "catalogLoading" ? "refresh" : "catalog"), element("p", [t(catalogStatus), t(catalogError) || catalogError].filter(Boolean).join(" · ")));
      if (catalogStatus !== "catalogLoading") status.append(button(t("retryCatalog"), refreshCatalog, "link", "refresh"));
      content.append(status);
    }
    if (!catalogStatus || state.mods.length || state.page === "installed") renderModList(content);
  }
}

if (isDesktop) document.addEventListener("contextmenu", event => event.preventDefault());
const previousPage = sessionStorage.getItem("page");
if (["installed", "settings"].includes(previousPage)) state.page = previousPage;
onRender(render);
state.appVersion = await appVersion();
const bundled = isDesktop ? await bundledCatalog() : {mods: []};
state.pinned = bundled.mods;
state.removalMods = bundled.removalMods ?? [];
state.previewMod = bundled.previewMod ?? null;
state.previewMods = bundled.previewMods ?? (bundled.previewMod ? [bundled.previewMod] : []);
state.appRepo = bundled.repo || state.appRepo;

async function authorize(document, signature) {
  state.updateTargets = await authorizeUpdates(document, signature);
  const known = new Set([...state.pinned, ...state.removalMods].map(mod => mod.id));
  const approved = new Set(state.updateTargets.map(mod => mod.id));
  state.removalMods.push(...JSON.parse(document).mods.filter(mod => approved.has(mod.id) && !known.has(mod.id)));
}
const verifyCatalog = isDesktop ? authorize : undefined;
let catalog = await restoreCatalog(localStorage, verifyCatalog);
state.mods = catalog ? sortMods(catalog, state.pinned) : [];

async function refreshCatalog() {
  catalogStatus = "catalogLoading";
  catalogError = "";
  render();
  try {
    catalog = await loadCatalog(localStorage, fetch, verifyCatalog);
    state.mods = sortMods(catalog, state.pinned);
    catalogStatus = "";
    if (isDesktop && state.game) void syncGameMods();
  } catch (error) {
    catalogError = error.message || String(error);
    catalogStatus = catalog ? "catalogCached" : "catalogUnavailable";
  }
  render();

}

hydrateIcons();
setupBatchMenu();
document.querySelectorAll("[data-page]").forEach(el => el.onclick = () => {
  if (state.batch?.phase === "running") return;
  // Keep the id-based card selection across pages; only a finished run needs clearing.
  if (state.batch?.phase === "done") state.batch = null;
  state.page = el.dataset.page;
  sessionStorage.setItem("page", state.page);
  render();
});
$("#search input").oninput = render;
$("#refresh-catalog").onclick = refreshCatalog;
$("#close").onclick = closeDialog;
applyLocale();
void refreshCatalog();
if (isDesktop) {
  window.addEventListener("focus", syncGameModsOnFocus);
  cachedPackages().then(result => { state.packages = {...result, ...state.packages}; render(); }).catch(() => {});
  detectGame().catch(error => show(t("failed"), element("p", String(error)), button(t("choose"), pickGame, "primary")));
  void checkApp(false);
}
