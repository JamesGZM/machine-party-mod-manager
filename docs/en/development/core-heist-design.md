# Core Heist Gameplay and Development Specification

**English** · [简体中文](../../zh-CN/development/core-heist-design.md) · [繁體中文](../../zh-TW/development/core-heist-design.md)

This specification defines the gameplay rules, arena layout, network synchronization, bot AI, and implementation milestones for **`core-heist` (Core Heist)**—the first native `"team_only"` co-op versus minigame mod built on `mpm-core` and `team-party`.

## 1. Module Identity & Admission Declaration

- **Mod ID**: `core-heist` (category: `game`)
- **Dependencies**: `requires: ["mpm-core", "team-party"]` (declared in both `mod.json` and [catalog/mods.json](../../../catalog/mods.json))
- **Slot Registration**: Dynamic slot (`>= 1000`) via `mpm-core.register_minigame()`, following [First-party mod development specification](mod-development.md) and [Co-op minigame design and admission gating](coop-minigame-gating.md).
- **Admission Gate (`"team_only"`)**:

```gdscript
"admission": {
	"mode_support": "team_only",
	"min_teams": 2,
	"max_teams": 4,
	"min_total_players": 2,
	"min_players_per_team": 1,
	"allow_local_couch": false,
}
```

- **Gating Behavior**:
  - Locked and greyed out in the lobby list (`[Team Mode]` / `[Online Only]`) and excluded from Default, Arcade, Local Couch, and the 15-slot CRT picker whenever `team-party` is off or local couch mode is active.
  - Asymmetric squads (e.g., `1v1`, `1v2`) remain eligible; if any team has only 1 active member (including after a disconnect), the Heavy Reactor Core auto-lightens for solo carry.

## 2. Core Gameplay Loop & 75-Second Pacing

The match is **host-authoritative** with a **3s prep + 75s match** structure:

1. **Prep Phase (3s)**:
   - Squads spawn in formation in front of their team-colored furnace while the camera frames the central foundry and team vaults.
2. **Phase 1: Standard Production (0–45s)**:
   - The central dispenser and dual short conveyors output **Standard Cells (`+1 pt`, `1.0×` speed)** and **Golden High-Voltage Cells (`+3 pts`, `0.88×` speed)**.
   - Deposit cells in your own furnace to score, or raid rival bases to steal unlocked cells.
3. **Phase 2: Heavy Reactor Core Drop (45–60s)**:
   - At `45s`, an industrial siren and floor beam telegraph a **Heavy Reactor Core (`+5 pts`)** at the center.
   - **Solo Carry**: `0.55×` movement speed; easily knocked loose by rival shoves.
   - **Dual Electromagnetic Resonance (Co-op Signature)**: When a **teammate** stays within `2.6m` of the carrier, a team-colored energy beam links them, boosting carry speed to **`1.15×`** and granting strong knockback resistance.
   - **Solo-Team Fallback**: If a team has only 1 alive member (1-player squad or mid-round disconnect), solo carry speed automatically lightens to `0.85×`.
4. **Phase 3: Overdrive Final 15s (60–75s)**:
   - Dispenser cadence doubles and a second Heavy Core drops at `62s`.
   - Any cell **stolen from a rival furnace and deposited in your own** during this phase earns a **`+1` steal bonus**.
5. **Settlement & Squads Scoring**:
   - Ends at `75s` (or early if only 1 active team retains online members).
   - Team score = sum of cells in the team's furnace + steal bonuses, synchronized through `team-party` Squads scoring.

## 3. Controls, Carrying, Throwing, Shoving & Stealing

Uses Machine Party's pure keyboard controls:

| Input | Empty Hands | Carrying Cell / Core |
| --- | --- | --- |
| `WASD` / Arrows | Move & face (auto-pickups nearby loose or unlocked rival-furnace cells) | Move & face (weighted carry speed multiplier) |
| `Space` | **Industrial Shove**: forward cone shove causing `0.45s` stagger and dropping a rival's carried cell; **zero friendly fire** via `team_support.are_teammates` | **Forward Toss / Pass**: toss `2.5m` ahead into your furnace or toward a teammate |

### Furnace Vault Rules
- **3.0s Magnetic Deposit Lock**: Deposited Standard (`+1`) and Golden (`+3`) cells gain a `3.0s` protective shield before rivals can steal them (1 at a time, highest unlocked value first).
- **Permanent Heavy Core Lock**: Deposited `+5` Heavy Reactor Cores **lock permanently** and cannot be stolen.

## 4. Arena Layout & Dynamic 2–4 Team Scaling

- **Arena Footprint**: Scales with active team count—`24m × 24m` for 2 teams (`2v2`, `4v4`), `28m × 28m` for 3–4 teams (`2v2v2`, `2v2v2v2`), enclosed by industrial guardrails on a dark charcoal sub-deck.
- **Symmetrical Team Bases**:
  - **2 Teams**: Opposite corners (SW vs. NE) with non-overlapping 4-player formation clearance (`4v4`).
  - **3 Teams**: 120° equilateral triangle vertices.
  - **4 Teams**: All 4 corners.
- **Mid-Field Flow & Industrial Backdrop**: Central elevated dispenser with dual short conveyors splitting spawns laterally, 4 mid-field bumper pillars, and a north factory back wall featuring rusted plating, overhead pipes, warm fluorescent tubes, and a large **3D Diegetic CRT Monitor** displaying live `MM:SS` countdown and phase (`STANDARD LINE` / `HEAVY CORE` / `OVERDRIVE`) in phosphor-green `Terminal F4`.
- **Lighting, Post-FX & Diegetic HUD**:
  - Warm low-saturation industrial lighting with `vignette.gdshader` and `posterization.gdshader` via `BackBufferCopy`.
  - Frameless outlined top-left team score row (leaving top-right completely clear for `team-party`'s HUD), official opening `YOU` bracket marker during prep and the first `2.5s` of play, large centered bold outlined `3-2-1-GO!` countdown, 0px-radius CRT bottom resonance bar, and a standalone-only 0px-radius CRT results panel (suppressed in official hosted matches).
- **Readable Vault Visuals**: Overhead team-colored scoreboards and physical furnace slots that visibly fill with deposited cell meshes so every player can immediately spot which rival leads and where to raid.
- **8-Player Battery Scaling**: Loose Standard (`10`→`18`) and Gold (`3`→`6`) caps plus conveyor spawn cadence scale cleanly with active team and player counts (`2v2v2`, `2v2v2v2`, `4v4`), reserving 2 pool slots for Heavy Cores.

## 5. Network Authority & State Sync

- **Host-Authoritative Simulation (`multiplayer.is_server()`)**: Cell spawning, ownership, toss trajectories, shove staggers, 3s locks, resonance links, and scores are simulated exclusively on the host.
- **Input & Snapshot RPCs**:
  - Client → Host: `move_dir: Vector2` and `action_pressed: bool`.
  - Host → Clients (`~20 Hz`): compact snapshot containing player transforms/stagger/carried cell index, pooled cell states (`loose` / `carried` / `deposited` / `locked` + positions), active resonance pairs, and team scores.

## 6. `lobby-bots` AI Controller (`ai_controller.gd`)

Bots switch dynamically across 4 role states:

1. **Co-op Escort**: When a teammate carries a `+5` Heavy Core, move within `2.0m` to maintain Electromagnetic Resonance and shove interceptors within `2.5m`.
2. **Carrier**: Route back to own furnace and press `Space` within `2.2m` to toss the cell in.
3. **Raider / Collector**: Prioritize loose Heavy Core > Golden Cell > highest-value unlocked cell in the #1 rival's furnace > Standard Cell.
4. **Defender**: Intercept rivals exiting own base with a stolen cell within `4.5m` and recover dropped cells.

## 7. File Structure & Performance Redlines

```text
mods/core-heist/
├── mod.json                 # id: "core-heist", requires: ["mpm-core", "team-party"]
├── main.gd                  # _mod_init / _mod_ready, admission registration & scene hook
├── config.gd                # Balance constants, colors, phase timings, point values
├── official_minigame.gd     # Standard Minigame signal interface
├── core_heist_game.gd       # Host-authoritative loop, cell pool, resonance & scoring
├── arena_meshes.gd          # Dynamic 2-4 team arena, conveyors, furnaces & pillars
├── ai_controller.gd         # Co-op escort & raid AI for lobby-bots
├── fx_pool.gd               # Pooled sparks/telegraphs/resonance via mpm-core.create_fx_pool()
├── hud_ui.gd                # Diegetic-first HUD: top-left scores, YOU marker, countdown & CRT resonance
├── team_support.gd          # Synced from mods/_shared/team-support/team_support.gd
├── self_test.gd             # --self-test headless verification
└── README.md                # Mod documentation
```

### Performance & Lint Redlines (per [First-party mod development specification](mod-development.md))
- **Zero runtime allocations**: Pre-allocate a fixed pool of up to **32 cell nodes** with shared cached meshes/materials; pre-allocate and frustum-warmup all FX via `mpm-core.create_fx_pool()`.
- **Hot-path bans**: No `get_property_list()`, `instantiate()`, `StandardMaterial3D.new()`, or `queue_free()` in `_process` / `_physics_process`.
- **Lint & headless compliance**: Must pass `node scripts/mod-lint.mjs` with explicit types on `.call()` / `.get()` / `.get_meta()`.

## 8. Implementation Milestones & Verification Plan

| Milestone | Deliverables | Acceptance Criteria |
| --- | --- | --- |
| **M1: Scaffold & Dynamic Arena** | `mod.json`, `main.gd`, `config.gd`, `arena_meshes.gd`, `"team_only"` admission | Passes `mpm-core` gating (locked in FFA, eligible in 2–4 team lobbies); 2/3/4-team meshes clean |
| **M2: Carry, Resonance & Vaults** | `core_heist_game.gd` cell pool, pickup/toss, shove drop, 3s lock & resonance | Headless verification of 0–45–60–75s phases, `1.15×` co-op resonance & `0.85×` solo-team fallback |
| **M3: Network Sync, HUD & AI** | 20 Hz snapshot RPCs, `hud_ui.gd`, `ai_controller.gd`, `fx_pool.gd` | Bots escort Heavy Core carriers and raid rival vaults; zero node leaks under 60 FPS stress |
| **M4: Tests, Packaging & Tier 3** | `self_test.gd`, sandbox test, R2 packaging, [catalog/mods.json](../../../catalog/mods.json) | `SELF_TEST_PASSED`, `npm run check:architecture`, `npm test`, and Windows Steam playtest verified |
