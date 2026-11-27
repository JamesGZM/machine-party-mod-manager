# Voltage Greed Gameplay and Development Specification

**English** · [简体中文](../../zh-CN/development/voltage-greed-design.md) · [繁體中文](../../zh-TW/development/voltage-greed-design.md)

This specification defines two deliverables:
1. The **Machine Party Signature Series Roadmap** — a 3-game lineup designed to capture the close-up stage humor, minimal-input greed/bluff tension, and Coach execution payoffs of classic vanilla *Machine Party* (e.g., *Table Manners*), adapted for **2–8+ players** and **both FFA and `team-party` modes** with zero voice-chat dependency.
2. The complete gameplay, close-up stage layout, clean-room asset reuse, networking, AI acting, and milestone specification for the first flagship entry: **`voltage-greed` (Voltage Greed)**.

## 1. Machine Party Signature Series Roadmap

Earlier first-party minigames (`roller-carnival`, `bubble-blitz`, `spike-ring`, `core-heist`, `bomb-cart`) focus on top-down or side-view arena movement and positioning. The **Signature Series** complements them with **close-up theatrical stages** where every player's hat, glasses, nervous animation, sabotage tell, and execution climax remain in frame together.

### Series Design Pillars
- **Close-Up Stage Framing**: Players sit or stand in a tight arc facing the camera and a central industrial apparatus, rather than roaming a large arena.
- **Ultra-Minimal Controls (2–3 Inputs)**: Learnable within 3 seconds on keyboard or controller without reading a wall of text.
- **Zero Voice-Chat Dependency & Natural Bot Acting**: Works cleanly in silent lobbies or with `lobby-bots` fills—every bluff, kick, or panic bail is broadcast visually and diegetically.
- **Dual-Mode Native (`"both"`) & 2–8+ Scaling**: Built for FFA chaos out of the box while supporting native `team-party` alliances and 5–8 player Overtime lobbies.

### 3-Game Lineup (Staggered Pacing, 40–65s Matches)

| Priority | Mod ID & Title | Origin & Rhythm | Core Hook & Execution Payoff | Team Mode (`team-party`) Synergy |
| --- | --- | --- | --- | --- |
| **P0 (First)** | **`voltage-greed`**<br>Voltage Greed | **Pure industrial original**<br>Real-time escalating push-your-luck (`~55s`, 3 rounds) | Strapped into forward-facing electric chairs inside a dark industrial chamber, hold to pull the lever and farm KPI while pushing a shared rear transformer toward a hidden `70%–100%` blow limit. Live players can slam `S` (`+12%` kick) to overload rivals; bailing too early triggers an Automated Factory Overseer slacker penalty. 2 lives (charred warning → lethal overload). | Parallel Circuit Resonance (`+20%` KPI when `>= 2` teammates hold live) + kamikaze sabotage (one banks early, another stays to detonate rivals). |
| **P1** | **`bonus-standoff`**<br>Bonus Standoff | ***Cash 'n Guns* × *Liar's Bar* adaptation**<br>Simultaneous secret pick & standoff reveal (`~50s`, 5 rounds) | Year-end factory bonus bars sit in the center while everyone hides a limited-ammo vanilla Deagle. Each 5s round, secretly pick: aim a live round to execute, bluff an empty chamber to scare rivals into ducking, or raise hands to survive safely and forfeit the split. | Coordinated crossfire deterrence and bluffing to protect the squad's main looter without friendly fire. |
| **P2** | **`revolver-table`**<br>Revolver Table | ***Buckshot Roulette* adaptation**<br>Rapid 4s turn-based execution (`~45–60s`) | 2–8 players sit around a rusted iron table beneath a laser-sighted rotary shotgun turret and an overhead CRT showing live/blank shell counts. On a 4s clock, shoot yourself for a blank score multiplier and extra turn, aim at a rival, or slap 1 random industrial gadget (X-ray peek, ejector, reverse). | Pass safe blank turns to teammates or trigger direction reversals to deflect lethal turns off endangered allies. |

---

## 2. `voltage-greed` Mod Positioning & Admission Contract

- **Mod ID**: `voltage-greed` (`category: "game"`)
- **Dependencies**: `requires: ["mpm-core"]` (declared in both [catalog/mods.json](../../../catalog/mods.json) and `mod.json`). Integrates natively with [`team-party`](../../../mods/team-party/README.md) via `team_support.gd` and degrades seamlessly to FFA when `team-party` is absent or disabled (per [coop-minigame-gating.md](coop-minigame-gating.md), `"both"` mods only require [`mpm-core`](../../../mods/mpm-core/README.md)).
- **Slot Registration**: Dynamic slot (`>= 1000`) via `mpm-core`'s `register_minigame()`, following [mod-development.md](mod-development.md) and [mod-sdk.md](mod-sdk.md).
- **Admission Contract (`"both"`, 2–8+ Players)**:

```gdscript
"admission": {
	"mode_support": "both",
	"min_teams": 2,
	"max_teams": 4,
	"min_total_players": 2,
	"min_players_per_team": 1,
	"allow_local_couch": true,
}
```

- **Dynamic Capacity**: Adapts seating, camera framing, and ranking across vanilla `2–4` player lobbies, `5–8+` player Overtime lobbies, local couch play, and `lobby-bots` fills without hardcoded 4-player limits.

## 3. Core Gameplay Loop, 3 Rounds, 2 Lives & Scoring

The match runs **Host-Authoritative** (`multiplayer.is_server()`) for approximately **55 seconds** across **3 escalating rounds** (3s opening prep + 3 rounds of 12–16s active phase + ~2.5s execution/inter-round transition):

1. **Prep Phase (3s)**:
   - Players spawn strapped into numbered bolted-iron electric chairs facing forward (`+Z`) toward the dead-center camera, backed by a towering central analog transformer, upper-left CRT monitor, and upper-right Automated Factory Overseer (Penalty Arc Emitter + Red Strobe Beacon).
   - Official opening `YOU` corner bracket tracks the local player during prep and the opening ~2.5s of Round 1 alongside a large outlined `3-2-1-GO!` countdown.
2. **Round 1 — Baseline Shift (`1.0×` KPI)**:
   - Pure baseline rules with no random Factory Monitor event so first-time players immediately grasp hold-to-farm, release-to-bank, and `S` voltage kicks.
3. **Round 2 — High-Voltage Shift (`1.25×` KPI)**:
   - Faster baseline voltage climb and `1.25×` KPI rate, introducing **1 mid-round Factory Monitor Industrial Event**.
4. **Round 3 — Critical Overtime (`1.5×–2.0×` KPI)**:
   - Base `1.5×` KPI multiplier (scaling to `2.0×` if Double Overtime triggers) plus **1 mid-round Factory Monitor Industrial Event**, giving players who fried earlier a realistic shot at a last-round comeback.

### Hidden Overload Threshold & Escalating Tells
- At the start of each round, the host rolls a secret detonation threshold in **`[70%, 100%]`** (never sent to clients before detonation).
- Public transformer voltage starts at `0%` and climbs continuously based on the number of live players holding their levers plus any `S` kicks.
- As public voltage crosses `50%` → `70%` → `85%`, the physical analog needle judders violently, overhead factory fluorescents strobe, chair wires spark, and transformer hum pitches upward.

### 2-Life Execution Rules & Early Victory
- Every player begins with **2 lives** (shown diegetically as **2 glowing fuse bulbs** mounted on their electric chair armrest).
- **1st Overload Fry (1 life remaining)**:
  - Anyone still holding their lever when the transformer crosses its secret threshold is shocked violently, turns charred and smoking with a crooked hat, **loses all unbanked KPI from the current round (`0` banked)**, blows 1 fuse bulb, and recovers for the next round.
- **2nd Overload Fry (0 lives remaining)**:
  - The chair blows out completely with pooled spark/blood splatter and a transformer overload blast. The player is **permanently eliminated** for the remaining round(s), keeping previously banked total KPI but unable to earn more.
- **Early Finish**: If at the end of Round 1 or Round 2 only `<= 1` player (FFA) or `<= 1` team (`team-party`) remains alive, skip remaining rounds and proceed straight to final scoring.

### Anti-Slacker Penalty (Automated Factory Overseer Callout)
- If **all live players bail out safely before the transformer explodes**, the Automated Factory Overseer System immediately strobes the back-wall red beacon and flags the **lowest-KPI performer of that round** (breaking ties by earliest release timestamp).
- The upper-right Penalty Arc Emitter fires a discipline bolt directly into that player's chair with an alarm klaxon, **halving (`-50%`) that player's banked KPI from that round** (minimum `0`), preventing trivial `0.2s` tap-and-bail farming.

## 4. Controls, Live-Only Voltage Sabotage & Factory Monitor Events

| Input | Behavior |
| --- | --- |
| **Hold `Space`** (or `W` / `↑` / `action_1`) | **Pull Lever / Farm KPI**: Draws live current through your chair. Unbanked round KPI ticks upward on an accelerating curve (higher public voltage = higher tick multiplier), while adding load to the shared transformer. |
| **Release `Space`** | **Bail Out & Lock Score**: Snaps down the chair's insulated safety visor, banking your current round KPI permanently and isolating you from transformer detonation. Cannot re-engage until the next round. |
| **Tap `S`** (or `↓` / `action_2`, **1 charge/round, LIVE-ONLY**) | **Voltage Kick / Sabotage**: **Usable ONLY while actively holding `Space`**. Disabled once bailed out so safe players cannot risk-free nuke survivors. Instantly spikes the shared transformer by **`+12%` public voltage**, grants the kicker a **`1.8s` personal KPI surge (`+35%` rate)**, and triggers an unmistakable switch-slap animation + bright arc line to the central transformer + loud breaker clank so everyone sees who kicked it. If `+12%` exceeds the hidden threshold, everyone live—including the kicker—fries immediately. |

### Factory Monitor Mid-Round Industrial Events (Rounds 2 & 3, 1 per Round)
1. **False Alarm**: Red beacon strobes and an overload klaxon blares for `1.2s` while actual voltage rise pauses briefly—pure psychological bait to scare nervous players into releasing early.
2. **Glitching Meter**: The central analog needle jitters randomly and the CRT percentage readout scrambles to `ERR // ???` for `1.5s` while true voltage keeps rising silently underneath.
3. **Double Overtime**: A gold factory bell rings for `2.5s`, temporarily doubling KPI tick rate (`2.0×`) to lure greedy players deeper into the danger zone.

## 5. Native Team Mode (`team-party`, `both`) Rules

Integrated via `team_support.gd` (automatically inactive in FFA):

- **Team Seating & Identification**: Teammates sit adjacent along the chair arc with team-colored base plates, name prefixes, and shared squad progress on `team-party`'s top-right HUD.
- **Parallel Circuit Resonance**: Whenever **`>= 2` living teammates hold their levers simultaneously**, a visible team-colored electric arc links their chairs and grants **`+20%` KPI gain rate** to all active teammates.
- **Kamikaze Sabotage Synergy**: Because final team standings aggregate total banked KPI (and sync via `team-party` Squads scoring), 1 teammate can bail out early to secure a high score while a remaining teammate stays live and slams `S` (`+12%`) to detonate the transformer and wipe unbanked KPI from greedy rival squads.
- **Solo-Team & Disconnect Compensation**: Teams starting with 1 player or reduced to 1 living player mid-match automatically receive a **`+10%` solo-circuit compensation bonus** so they remain competitive without parallel resonance.

## 6. Close-Up Stage Layout, 2–8P Camera & Clean-Room Asset Reuse

- **Adaptive Close-Up Stage (Forward-Facing *Green Pea*-Grade Chamber)**:
  - **2–4 Players**: Single gently curved front row facing forward (`+Z`) toward a dead-center symmetrical camera, backed by the towering central analog transformer dial, upper-left CRT telemetry monitor, and upper-right Automated Penalty Arc Emitter + Red Strobe Beacon—keeping hats, glasses, shaking postures, armrest fuses, and footbar mini-LCDs crisp and prominent.
  - **5–8+ Players**: Two-tier staggered steel interrogation riser (back row elevated at `y = 0.92` behind the front row, both facing `+Z`) with dead-center symmetrical camera framing (`x = 0.0`) so all 8 players, arcs, and the central dial remain legible in one shot.
- **Clean-Room Runtime Asset Reuse (Zero Vanilla Assets Committed)**:
  - Dynamically loads official textures/meshes from mounted `Machine Party.pck` when present (enclosed *Green Pea*-style chamber panels, `metal sheet2 chair/table`, `bnr floor tiles`, `metal shelf sheet2`, `cardboard box2`, `metal sheet console1`, `sitting_on_dinner_chair_idle.res`, `main character2.glb` + `CustomizationAssigner` cosmetics), with procedural fallback meshes/materials for standalone macOS preview (`run_mac.sh`).
  - Official `vignette.gdshader` + `posterization.gdshader` post-FX (`SCREEN_WIDTH=320`, `12`-step color quantization, enclosed cold-cyan ceiling `OmniLight3D` pools) and official blood/spark/explosion FX managed via `mpm-core.create_fx_pool()`.
- **Diegetic-First HUD**:
  - Rear-center 3D recessed analog needle gauge + upper-left CRT monitor (voltage percentage, round indicator, active status) + upper-right Automated Penalty Arc Emitter & red strobe; per-chair footbar mini-LCD displaying live unbanked KPI, banked total, and 2 physical fuse bulbs.
  - Top-right corner kept 100% clear for `team-party` HUD; compact bottom-center control legend (`HOLD [SPACE] FARM` · `RELEASE BANK` · `[S] +12% KICK`).

## 7. Host-Authoritative Networking & 20 Hz Sync

- **Host Authority (`multiplayer.is_server()`)**: Owns hidden threshold generation, voltage integration, live/bailed/fried states, live-only `S` kick validation, Factory Monitor event scheduling, slacker detection, 2-life elimination, and final score submission.
- **Uplink Input RPCs**: Reliable client-to-host RPCs for lever state (`set_holding_rpc(holding: bool)`) and sabotage trigger (`trigger_kick_rpc()`).
- **Downlink Snapshots (~20 Hz, `0.05s`)**: Compact state dictionary (`round_idx`, `phase`, `phase_timer`, `display_voltage`, `event_id`, `event_timer`, and per-player `{holding, bailed, alive, lives, round_kpi, total_kpi, kick_used, fried_round}`), paired with reliable event RPCs for transformer detonation, visible kick arcs, Penalty Arc Emitter slacker reprimands, and round results.

## 8. `lobby-bots` AI Acting Design (`ai_controller.gd`)

Each bot rolls an archetype per match (*Cautious Clerk*, *Greedy Gambler*, *Chaos Saboteur*) with randomized target bail thresholds (`52%–88%`), human-like reaction delays, and readable visual tells:
- **Event Reactions**: Bots occasionally fall for **False Alarm** events and panic-bail visibly, or hesitate briefly during **Glitching Meter**.
- **Sabotage Logic**:
  - In FFA: *Chaos Saboteur* bots trigger `S` around `55%–75%` voltage when tied or slightly behind, while cautious bots tend to bail out immediately after witnessing a kick.
  - In Team Party: If a teammate already banked a strong lead while enemy carries remain live above `68%` voltage, a bot with 2 lives can deliberately sacrifice a fuse by slamming `S` to detonate enemy unbanked scores.

## 9. Planned Module Structure & Performance Redlines

```text
mods/voltage-greed/
├── mod.json                 # id: "voltage-greed", requires: ["mpm-core"]
├── main.gd                  # _mod_init / _mod_ready, "both" admission & scene registration
├── config.gd                # Round multipliers, thresholds, 2-8P seating geometry & constants
├── official_minigame.gd     # Vanilla Minigame signal interface adapter
├── voltage_greed_game.gd    # Host-authoritative simulation, 2-life rules, events & scoring
├── arena_meshes.gd          # Enclosed Green Pea-grade chamber, forward-facing chairs/riser, transformer, CRT & Penalty Arc Emitter
├── ai_controller.gd         # Personality-driven lobby-bots acting, panic bails & sabotage AI
├── fx_pool.gd               # Pre-allocated spark/arc/char/blood FX pools with frustum warmup
├── hud_ui.gd                # Diegetic chair LCDs, YOU marker, 3-2-1-GO & key legend
├── team_support.gd          # Synced from mods/_shared/team-support/team_support.gd
├── self_test.gd             # --self-test headless simulation, 2-8P & team logic verification
└── README.md                # Mod documentation
```

### Performance & Contract Redlines (Aligned with [mod-development.md](mod-development.md))
- **Zero Runtime Allocations**: All electric arcs, transformer sparks, overload flashes, and blood splatters use pre-built `mpm-core.create_fx_pool()` pools warmed inside the camera frustum during the 3s prep phase.
- **Hot-Path Prohibitions**: No `get_property_list()`, `Mesh`/`StandardMaterial3D` allocation, or `queue_free()` in `_process` or `_physics_process`.
- **Headless & Lint Compliance**: Must pass `node scripts/mod-lint.mjs` (explicit types for `call()` / `get()` / `get_meta()`).

## 10. Development Milestones & Acceptance Checklist

| Milestone | Deliverables | Acceptance Criteria |
| --- | --- | --- |
| **M1: Close-Up Stage & Admission** | `mod.json`, `main.gd`, `config.gd`, `arena_meshes.gd`, `"both"` admission | Passes `mpm-core` gating in FFA, `team-party`, and local couch; clean 2–4P row and 5–8P two-tier riser camera framing |
| **M2: 3-Round Sim, Sabotage & Team Rules** | `voltage_greed_game.gd` 3 rounds, hidden threshold, 2 lives, live-only `S` kick, Automated Overseer slacker penalty, 3 events, parallel/kamikaze team logic | Headless verification of hold/bail scoring, post-bail `S` lockout, 1st fry vs. 2nd elimination, slacker penalty, and team resonance |
| **M3: Networking, Diegetic HUD, FX & AI** | 20 Hz snapshots + reliable event RPCs, `hud_ui.gd`, `fx_pool.gd` frustum warmup, `ai_controller.gd` | Bots react believably to False Alarms and execute team kamikaze kicks; 60 FPS stress test with zero node leaks |
| **M4: Tests, Packaging & Acceptance** | `self_test.gd`, `run_mac.sh` preview & cover screenshot, `scripts/pack-mod.mjs`, [catalog/mods.json](../../../catalog/mods.json) | `SELF_TEST_PASSED`, `npm run check:architecture`, and `npm test` pass; Tier 3 Windows Steam multiplayer acceptance |
