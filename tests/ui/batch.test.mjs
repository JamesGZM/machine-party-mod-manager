import assert from "node:assert/strict";
import test from "node:test";
import {
  BATCH_KINDS, batchAction, batchConfirmKey, batchEligible, batchEmptyKey, batchLabelKey,
  batchMatches, batchQueue, batchRunningKey, batchSelectAll, batchSelectable,
  batchSelectedCount, batchSummary, batchTargets, batchToggle, canRunBatch
} from "../../apps/desktop/ui/batch.js";

const row = (overrides = {}) => ({ready: true, action: "install", removable: false, ...overrides});

const mods = [
  {id: "a", action: "install", removable: false},
  {id: "b", action: "updateMod", removable: true},
  {id: "c", action: "uninstall", removable: true},
  {id: "d", action: "review", removable: false},
  {id: "e", action: "adoptManual", removable: false}
];
const rowOf = mod => row({action: mod.action, removable: mod.removable});

test("operations map to the single-mod actions they reuse", () => {
  assert.deepEqual(BATCH_KINDS, ["install", "update", "uninstall"]);
  assert.equal(batchAction("install"), "install");
  assert.equal(batchAction("update"), "updateMod");
  assert.equal(batchAction("uninstall"), "uninstall");
  assert.equal(batchAction("unknown"), "");
  assert.equal(batchAction(""), "");
});

test("state matching is independent of scan readiness", () => {
  assert.equal(batchMatches("install", row()), true);
  assert.equal(batchMatches("install", row({ready: false})), true);
  assert.equal(batchMatches("install", row({removable: true})), false, "never offer install for a mod with an install record");
  assert.equal(batchMatches("install", row({action: "updateMod", removable: true})), false);
  assert.equal(batchMatches("install", row({action: "uninstall", removable: true})), false);
  assert.equal(batchMatches("install", row({action: "review"})), false);
  assert.equal(batchMatches("install", row({action: "adoptManual"})), false);
  assert.equal(batchMatches("install", row({action: "switch"})), false);
  assert.equal(batchMatches("bogus", row()), false);
  assert.equal(batchMatches("install", null), false);
});

test("update only matches installed mods with an approved newer release", () => {
  assert.equal(batchMatches("update", row({action: "updateMod", removable: true})), true);
  assert.equal(batchMatches("update", row({action: "install"})), false);
  assert.equal(batchMatches("update", row({action: "uninstall", removable: true})), false, "up-to-date installs are not updatable");
  assert.equal(batchMatches("update", row({action: "review", removable: true})), false);
  assert.equal(batchMatches("update", row({action: "switch"})), false);
});

test("uninstall matches every installed mod, including ones with an available update", () => {
  assert.equal(batchMatches("uninstall", row({action: "uninstall", removable: true})), true);
  assert.equal(batchMatches("uninstall", row({action: "updateMod", removable: true})), true);
  assert.equal(batchMatches("uninstall", row({action: "review", removable: true})), true, "needsRepair can be restored to vanilla");
  assert.equal(batchMatches("uninstall", row({action: "install", removable: true})), true, "removable flag wins over a stale action");
  assert.equal(batchMatches("uninstall", row({action: "checking", removable: true})), false);
  assert.equal(batchMatches("uninstall", row({action: "retryCheck", removable: true})), false);
  assert.equal(batchMatches("uninstall", row()), false, "manual installs have no transaction and cannot be removed by the manager");
  assert.equal(batchMatches("uninstall", row({action: "adoptManual"})), false);
  assert.equal(batchMatches("uninstall", row({action: "switch"})), false);
});

test("eligibility additionally requires a finished game scan", () => {
  for (const kind of BATCH_KINDS) {
    assert.equal(batchEligible(kind, row({ready: false})), false, kind);
    assert.equal(batchEligible(kind, row({ready: false, action: "updateMod", removable: true})), false, kind);
    assert.equal(batchEligible(kind, null), false, kind);
    assert.equal(batchEligible(kind, undefined), false, kind);
  }
  assert.equal(batchEligible("bogus", row()), false);
  assert.equal(batchEligible("install", row()), true);
});

test("selectable ids keep catalog order and ignore all ineligible rows", () => {
  assert.deepEqual(batchSelectable(mods, "install", rowOf), ["a"]);
  assert.deepEqual(batchSelectable(mods, "update", rowOf), ["b"]);
  assert.deepEqual(batchSelectable(mods, "uninstall", rowOf), ["b", "c"]);
  assert.deepEqual(batchSelectable(mods, "install", () => row({ready: false})), []);
});

test("menu badges follow the ticked selection, not the whole catalog", () => {
  // Only "a" is ticked: install shows 1, update/uninstall show 0 even though
  // other cards in the catalog are eligible for those operations.
  assert.equal(batchSelectedCount(mods, "install", rowOf, ["a"]), 1);
  assert.equal(batchSelectedCount(mods, "update", rowOf, ["a"]), 0);
  assert.equal(batchSelectedCount(mods, "uninstall", rowOf, ["a"]), 0);
  assert.equal(batchSelectedCount(mods, "install", rowOf, []), 0);
  assert.equal(batchSelectedCount(mods, "install", rowOf, null), 0);
  // Ticking three cards: the badge is the intersection with each operation.
  assert.equal(batchSelectedCount(mods, "install", rowOf, ["a", "b", "c"]), 1);
  assert.equal(batchSelectedCount(mods, "update", rowOf, ["a", "b", "c"]), 1);
  assert.equal(batchSelectedCount(mods, "uninstall", rowOf, ["a", "b", "c"]), 2);
  assert.equal(batchSelectedCount(mods, "uninstall", rowOf, ["z"]), 0, "unknown ids never count");
});

test("badges ignore scan readiness so ticked cards stay visible while scanning", () => {
  assert.equal(batchSelectedCount(mods, "install", () => row({ready: false, action: "checking"}), ["a"]), 0);
  assert.equal(batchSelectedCount(mods, "install", rowOf, ["a"]), 1);
  // A pure state match is still counted even if the row is not executable yet.
  assert.equal(batchSelectedCount([{id: "a"}], "install", () => row({ready: false}), ["a"]), 1);
});

test("batch targets only contain ticked cards and report filtered ones", () => {
  // Ticked a,b,c,d. For install only "a" is eligible; b,c,d are filtered out.
  assert.deepEqual(batchTargets(mods, "install", rowOf, ["a", "b", "c", "d"]),
    {queue: ["a"], filtered: ["b", "c", "d"]});
  assert.deepEqual(batchTargets(mods, "update", rowOf, ["a", "b", "c"]),
    {queue: ["b"], filtered: ["a", "c"]});
  assert.deepEqual(batchTargets(mods, "uninstall", rowOf, ["a", "b", "c", "d"]),
    {queue: ["b", "c"], filtered: ["a", "d"]});
  // Never operate on unticked cards, even when they are eligible.
  assert.deepEqual(batchTargets(mods, "install", rowOf, []), {queue: [], filtered: []});
  assert.deepEqual(batchTargets(mods, "uninstall", rowOf, ["a"]), {queue: [], filtered: ["a"]});
  assert.deepEqual(batchTargets(mods, "install", rowOf, ["c", "a"]),
    {queue: ["a"], filtered: ["c"]}, "queue keeps catalog order regardless of tick order");
  assert.deepEqual(batchTargets(mods, "install", () => row({ready: false}), ["a"]),
    {queue: [], filtered: ["a"]}, "scan not ready means nothing is executed");
  assert.deepEqual(batchTargets(mods, "install", rowOf, ["a", "z"]),
    {queue: ["a"], filtered: []}, "stale selections are dropped silently");
});

test("running requires at least one checked mod", () => {
  assert.equal(canRunBatch([]), false);
  assert.equal(canRunBatch(null), false);
  assert.equal(canRunBatch(undefined), false);
  assert.equal(canRunBatch(["spike-ring"]), true);
});

test("summary separates successes, failures and skipped stale entries", () => {
  assert.deepEqual(batchSummary([]), {ok: 0, fail: 0, skip: 0});
  assert.deepEqual(batchSummary(["ok", "ok", "downloadFailed", "skip"]), {ok: 2, fail: 1, skip: 1});
  assert.deepEqual(batchSummary(["ok", "gameRunning", "skip", "skip"]), {ok: 1, fail: 1, skip: 2});
});

test("i18n keys are only produced for supported operations", () => {
  assert.equal(batchLabelKey("install"), "batchInstall");
  assert.equal(batchLabelKey("update"), "batchUpdate");
  assert.equal(batchLabelKey("uninstall"), "batchUninstall");
  assert.equal(batchRunningKey("install"), "batchRunningInstall");
  assert.equal(batchRunningKey("update"), "batchRunningUpdate");
  assert.equal(batchRunningKey("uninstall"), "batchRunningUninstall");
  assert.equal(batchEmptyKey("update"), "batchEmptyUpdate");
  assert.equal(batchConfirmKey("install"), "batchConfirmInstall");
  assert.equal(batchConfirmKey("update"), "batchConfirmUpdate");
  assert.equal(batchConfirmKey("uninstall"), "batchConfirmUninstall");
  assert.equal(batchLabelKey("bogus"), "");
  assert.equal(batchRunningKey(""), "");
  assert.equal(batchEmptyKey(null), "");
  assert.equal(batchConfirmKey(""), "");
});

test("toggling a checkbox keeps other selections and their order", () => {
  assert.deepEqual(batchToggle(["a", "b"], "c", true), ["a", "b", "c"]);
  assert.deepEqual(batchToggle(["a", "b"], "a", false), ["b"]);
  assert.deepEqual(batchToggle(["a", "b"], "b", true), ["a", "b"], "checking twice cannot duplicate");
  assert.deepEqual(batchToggle([], "a", false), []);
  assert.deepEqual(batchToggle(null, "a", true), ["a"]);
  assert.deepEqual(batchToggle(undefined, "a", true), ["a"]);
});

test("select all merges visible ids without losing earlier picks", () => {
  assert.deepEqual(batchSelectAll(["a"], ["b", "c"]), ["a", "b", "c"]);
  assert.deepEqual(batchSelectAll(["b"], ["a", "b"]), ["b", "a"]);
  assert.deepEqual(batchSelectAll(null, ["a"]), ["a"]);
  assert.deepEqual(batchSelectAll(["a"], null), ["a"]);
});

test("the run queue keeps catalog order and drops stale selections", () => {
  assert.deepEqual(batchQueue(["a", "b", "c"], ["c", "a"]), ["a", "c"]);
  assert.deepEqual(batchQueue(["a", "b"], ["z"]), []);
  assert.deepEqual(batchQueue([], ["a"]), []);
  assert.deepEqual(batchQueue(null, null), []);
});
