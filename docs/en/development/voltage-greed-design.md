# Voltage Greed Gameplay and Development Specification

**English** · [简体中文](../../zh-CN/development/voltage-greed-design.md) · [繁體中文](../../zh-TW/development/voltage-greed-design.md)

This specification defines two deliverables:
1. The **Machine Party Signature Series Roadmap** — a 3-game lineup designed to capture the close-up stage humor, minimal-input greed/bluff tension, and Coach execution payoffs of classic vanilla *Machine Party* (e.g., *Table Manners*), adapted for **2–8+ players** and **both FFA and `team-party` modes** with zero voice-chat dependency.
2. The complete gameplay, close-up stage layout, clean-room asset reuse, networking, AI acting, and milestone specification for the first flagship entry: **`voltage-greed` (Voltage Greed)**.

## 1. Machine Party Signature Series Roadmap

Earlier first-party minigames (`roller-carnival`, `bubble-blitz`, `spike-ring`, `core-heist`, `bomb-cart`) focus on top-down or side-view arena movement and positioning. The **Signature Series** complements them with **close-up theatrical stages** where every player's hat, glasses, nervous animation, sabotage tell, and execution climax remain in frame together.

### Series Design Pillars
- **Close-Up Stage Framing**: Players sit or stand in a tight arc facing the Coach and a central mechanical prop, rather than roaming a large arena.
- **Ultra-Minimal Controls (2–3 Inputs)**: Learnable within 3 seconds on keyboard or controller without reading a wall of text.
- **Zero Voice-Chat Dependency & Natural Bot Acting**: Works cleanly in silent lobbies or with `lobby-bots` fills—every bluff, kick, or panic bail is broadcast visually and diegetically.
- **Dual-Mode Native (`"both"`) & 2–8+ Scaling**: Built for FFA chaos out of the box while supporting native `team-party` alliances and 5–8 player Overtime lobbies.

### 3-Game Lineup (Staggered Pacing, 40–65s Matches)

| Priority | Mod ID & Title | Origin & Rhythm | Core Hook & Execution Payoff | Team Mode (`team-party`) Synergy |
| --- | --- | --- | --- | --- |
| **P0 (First)** | **`voltage-greed`**<br>Voltage Greed | **Pure industrial original**<br>Real-time escalating push-your-luck (`~55s`, 3 rounds) | Strapped into electric chairs, hold to pull the lever and farm KPI while pushing a shared transformer toward a hidden `70%–100%` blow limit. Live players can slam `S` (`+12%` kick) to overload rivals; bailing too early triggers a Coach slacker penalty. 2 lives (charred warning → lethal overload). | Parallel Circuit Resonance (`+20%` KPI when `>= 2` teammates hold live) + kamikaze sabotage (one banks early, another stays to detonate rivals). |
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
   - Players spawn strapped into numbered industrial electric chairs facing the central analog transformer and the Coach's podium.
   - Official opening `YOU` corner bracket tracks the local player during prep and the opening ~2.5s of Round 1 alongside a large outlined `3-2-1-GO!` countdown.
2. **Round 1 — Baseline Shift (`1.0×` KPI)**:
   - Pure baseline rules with no random Coach event so first-time players immediately grasp hold-to-farm, release-to-bank, and `S` voltage kicks.
3. **Round 2 — High-Voltage Shift (`1.25×` KPI)**:
   - Faster baseline voltage climb and `1.25×` KPI rate, introducing **1 mid-round Coach Industrial Event**.
4. **Round 3 — Critical Overtime (`1.5×–2.0×` KPI)**:
   - Base `1.5×` KPI multiplier (scaling to `2.0×` if Double Overtime triggers) plus **1 mid-round Coach Industrial Event**, giving players who fried earlier a realistic shot at a last-round comeback.

### Hidden Overload Threshold & Escalating Tells
- At the start of each round, the host rolls a secret detonation threshold in **`[70%, 100%]`** (never sent to clients before detonation).
- Public transformer voltage starts at `0%` and climbs continuously based on the number of live players holding their levers plus any `S` kicks.
- As public voltage crosses `50%` → `70%` → `85%`, the physical analog needle judders violently, overhead factory fluorescents strobe, chair wires spark, and transformer hum pitches upward.

### 2-Life Execution Rules & Early Victory
- Every player begins with **2 lives** (shown diegetically as **2 glowing fuse bulbs** mounted on their electric chair armrest).
- **1st Overload Fry (1 life remaining)**:
  - Anyone still holding their lever when the transformer crosses its secret threshold is shocked violently, turns charred and smoking with a crooked hat, **loses all unbanked KPI from the current round (`0` banked)**, blows 1 fuse bulb, and recovers for the next round.
- **2nd Overload Fry (0 lives remaining)**:
  - The chair blows out completely with pooled spark/blood splatter and a Coach execution flourish. The player is **permanently eliminated** for the remaining round(s), keeping previously banked total KPI but unable to earn more.
- **Early Finish**: If at the end of Round 1 or Round 2 only `<= 1` player (FFA) or `<= 1` team (`team-party`) remains alive, skip remaining rounds and proceed straight to final scoring.

### Anti-Slacker Penalty (Coach Callout)
- If **all live players bail out safely before the transformer explodes**, the Coach immediately steps forward and calls out the **lowest-KPI performer of that round** (breaking ties by earliest release timestamp).
- The Coach administers a public reprimand (chair discipline jolt + Deagle warning shot), **halving (`-50%`) that player's banked KPI from that round** (minimum `0`), preventing trivial `0.2s` tap-and-bail farming.

## 4. Controls, Live-Only Voltage Sabotage & Coach Events

| Input | Behavior |
| --- | --- |
| **Hold `Space`** (or `W` / `↑` / `action_1`) | **Pull Lever / Farm KPI**: Draws live current through your chair. Unbanked round KPI ticks upward on an accelerating curve (higher public voltage = higher tick multiplier), while adding load to the shared transformer. |
| **Release `Space`** | **Bail Out & Lock Score**: Snaps down the chair's insulated safety visor, banking your current round KPI permanently and isolating you from transformer detonation. Cannot re-engage until the next round. |
| **Tap `S`** (or `↓` / `action_2`, **1 charge/round, LIVE-ONLY**) | **Voltage Kick / Sabotage**: **Usable ONLY while actively holding `Space`**. Disabled once bailed out so safe players cannot risk-free nuke survivors. Instantly spikes the shared transformer by **`+12%` public voltage**, grants the kicker a **`1.8s` personal KPI surge (`+35%` rate)**, and triggers an unmistakable switch-slap animation + bright arc line to the central transformer + loud breaker clank so everyone sees who kicked it. If `+12%` exceeds the hidden threshold, everyone live—including the kicker—fries immediately. |

### Coach Mid-Round Industrial Events (Rounds 2 & 3, 1 per Round)
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

- **Adaptive Close-Up Stage**:
  - **2–4 Players**: Single gently curved front row facing the central analog transformer and Coach podium, keeping hats, glasses, shaking postures, armrest fuses, and mini-LCD scores crisp and prominent.
  - **5–8+ Players**: Two-tier semi-circular lab/courtroom riser (staggered back row slightly elevated behind the front row) with dynamic camera FOV/distance adjustment so all 8 players and the central gauge remain legible in one shot.
- **Clean-Room Runtime Asset Reuse (Zero Vanilla Assets Committed)**:
  - Dynamically loads official resources from mounted `Machine Party.pck` when present, with procedural fallback meshes/materials for standalone macOS preview (`run_mac.sh`):
    - Coach rigs & animations (`res://minigames/green_pea/models/character coach1/character coach1.glb`, `res://minigames/green_pea/models/pea game coach with deagle1/pea game coach with deagle1.glb`, `coach_deagle_ready_up.res`, `coach_looking_at_players.res`).
    - Sitting idle reference (`res://minigames/green_pea/animations/sitting_on_dinner_chair_idle.res`) + official player customization (`CustomizationAssigner` hats, glasses, suit colors).
    - Official `vignette.gdshader` + `posterization.gdshader` post-FX and official blood/spark/explosion FX managed via `mpm-core.create_fx_pool()`.
- **Diegetic-First HUD**:
  - Central physical 3D analog needle gauge + overhead CRT monitor (round indicator, event banner, active survivor count); per-chair mini-LCD displaying live unbanked KPI, banked total, and 2 physical fuse bulbs.
  - Top-right corner kept 100% clear for `team-party` HUD; compact bottom-center control legend (`HOLD [SPACE] FARM` · `RELEASE BANK` · `[S] +12% KICK`).

## 7. Host-Authoritative Networking & 20 Hz Sync

- **Host Authority (`multiplayer.is_server()`)**: Owns hidden threshold generation, voltage integration, live/bailed/fried states, live-only `S` kick validation, Coach event scheduling, slacker detection, 2-life elimination, and final score submission.
- **Uplink Input RPCs**: Reliable client-to-host RPCs for lever state (`set_holding_rpc(holding: bool)`) and sabotage trigger (`trigger_kick_rpc()`).
- **Downlink Snapshots (~20 Hz, `0.05s`)**: Compact state dictionary (`round_idx`, `phase`, `phase_timer`, `display_voltage`, `event_id`, `event_timer`, and per-player `{holding, bailed, alive, lives, round_kpi, total_kpi, kick_used, fried_round}`), paired with reliable event RPCs for transformer detonation, visible kick arcs, Coach slacker reprimands, and round results.

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
├── arena_meshes.gd          # Close-up electric chair arc/riser, analog transformer & Coach stage
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
| **M2: 3-Round Sim, Sabotage & Team Rules** | `voltage_greed_game.gd` 3 rounds, hidden threshold, 2 lives, live-only `S` kick, Coach slacker callout, 3 events, parallel/kamikaze team logic | Headless verification of hold/bail scoring, post-bail `S` lockout, 1st fry vs. 2nd elimination, slacker penalty, and team resonance |
| **M3: Networking, Diegetic HUD, FX & AI** | 20 Hz snapshots + reliable event RPCs, `hud_ui.gd`, `fx_pool.gd` frustum warmup, `ai_controller.gd` | Bots react believably to False Alarms and execute team kamikaze kicks; 60 FPS stress test with zero node leaks |
| **M4: Tests, Packaging & Acceptance** | `self_test.gd`, `run_mac.sh` preview & cover screenshot, `scripts/pack-mod.mjs`, [catalog/mods.json](../../../catalog/mods.json) | `SELF_TEST_PASSED`, `npm run check:architecture`, and `npm test` pass; Tier 3 Windows Steam multiplayer acceptance |
