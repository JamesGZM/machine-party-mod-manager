# Bomb Cart Gameplay and Development Specification

**English** · [简体中文](../../zh-CN/development/bomb-cart-design.md) · [繁體中文](../../zh-TW/development/bomb-cart-design.md)

This specification defines the complete gameplay rules, adaptive 2–4 team arena geometry, foundry-railyard visual direction, network synchronization, AI behavior, and development milestones for **`bomb-cart` (Bomb Cart)**, a 2–4 team adaptive rail assault minigame mod built on `mpm-core` and `team-party`.

## 1. Mod Positioning & Admission Contract

- **Mod ID**: `bomb-cart` (`category: "game"`)
- **Dependencies**: `requires: ["mpm-core", "team-party"]` (declared in both [catalog/mods.json](../../../catalog/mods.json) and `mod.json`)
- **Slot Registration**: Dynamic slot (`>= 1000`) via `mpm-core`'s `register_minigame()`, following the [First-party mod development specification](mod-development.md) and [Co-op minigame design and admission gating](coop-minigame-gating.md).
- **Admission Contract (2–4 Team `"team_only"`)**:

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
  - `bomb-cart` unlocks across 2-team (`2v2` / `4v4`), 3-team (`2v2v2`), and 4-team (`2v2v2v2`) online `team-party` rooms, adapting its rail topology automatically to the active team IDs (including sparse team IDs such as `[1, 3]` or `[2, 4]`).
  - When `team-party` is disabled (FFA) or in local couch mode, the lobby left-hand list grays out and locks the entry (`[Needs Team Mode]` / `[Online Only]`), and excludes it from the Default playlist, Arcade pool, and 15-slot CRT picker.
- **Asymmetric / Disconnect Underdog Fallback**:
  - Allows asymmetric starts (e.g., `1v2`) and mid-match disconnects. When alive team sizes differ, smaller intact teams receive proportional push-weight compensation (`clampf(larger / smaller, 1.0, 1.5)`).
  - If only one active intact team retains online members, immediate team victory and synchronized Squads scoring trigger.

## 2. Core Gameplay Loop, 3-Phase Escalation & Victory Rules

The match runs **Host-Authoritative** (`multiplayer.is_server()`) for **3s Prep + 75s Match** (plus an optional **10s Sudden Death Overtime** if tied at `t = 75s`):

1. **Prep Phase (3s)**:
   - Teams spawn in formation in front of their own Blast Doors facing the central rail / turntable hub.
   - Official opening `YOU` bracket marker tracks the local player during prep and the first ~2.5s of live play alongside a large bold outlined `3-2-1-GO!` countdown.
2. **Phase 1: Standard Push (0–40s)**:
   - Base cart push speed multiplier `1.0×`; Steam Valves cycle every `14s` for flanking control.
3. **Phase 2: Fuse Ignited (40–60s)**:
   - Base cart push speed rises to `1.35×` to break stalemates.
   - Every `8s`, the Bomb Cart projects a **`1.2s` red danger ring (`3.2m` radius)** before emitting a **Shockwave Pulse** that knocks back players caught inside (`0.35s` stagger).
4. **Phase 3: Critical Overload (60–75s)**:
   - Base cart push speed rises to `1.75×`, **all** Steam Valves activate simultaneously on a `10s` cycle, and the warhead flashes rapid critical red with alarm cues for dramatic late-game comebacks.
5. **Victory & Squads Scoring**:
   - **2 Teams**:
     - **Blast Door Breach (Instant KO)**: Reaching `+11.5m` (East Blast Door) awards the West team instant victory; reaching `-11.5m` (West Blast Door) awards the East team instant victory.
     - **Timer Detonation (75s)**: Half-field position (`|cart_x| > 0.15m`) decides; ties enter 10s Sudden Death (`±0.6m`).
   - **3–4 Teams**:
     - **Blast Door Breach Elimination**: Pushing the cart to `10.5m` down an intact branch detonates that team's Blast Door, marks its players `alive = false` (updating `team-party`'s top-right HUD immediately), awards breach credit to the attacking team, and resets the cart to the central turntable `(0, 0)` with a `1.2s` pause. When only 1 intact team remains, that team wins immediately.
     - **Timer Detonation (75s) & Overtime**: Intact teams outrank breached teams; safe intact teams outrank a threatened team whose branch currently holds the cart (`branch_dist > 0.45m`) and break ties by breach credit. Dead-center ties enter 10s Sudden Death where pushing `> 0.8m` onto any intact rival arm wins immediately.
   - Final scores sync through `team-party` Squads scoring back to the room leaderboard.

## 3. Controls, Push Physics, Power Ram & Steam Boost Valves

Follows Machine Party's minimal 2-input keyboard scheme (`WASD / Arrows` + `Space`):

| Input | Behavior |
| --- | --- |
| `WASD` / Arrows | Move and steer (`6.6 m/s`). Stepping inside the cart's **`2.6m` Push Aura** applies push force (along the straight rail in 2-team mode, or away from own door / down an enemy intact branch via the central turntable in 3–4 team mode). Net advantage beyond `+2` follows diminishing returns so 4v4 and 2v2v2v2 stay tense. |
| `Space` (shared `0.95s` cooldown, context-sensitive priority) | 1. **Industrial Shove**: If an enemy is within the `2.1m` front cone, knocks them out of the push zone with `0.45s` stun and `8.5 m/s` impulse; **zero friendly fire** via `team_support.are_teammates`.<br>2. **Power Ram**: Otherwise, if within `2.4m` of the Bomb Cart, slams the cart for an immediate directional velocity burst + metal spark VFX.<br>3. **Quick Valve Slam**: Otherwise, if standing on an active Steam Valve pad, triggers the valve immediately (standing uncontested for `0.6s` also auto-triggers it). |

### Steam Boost Valves (Adaptive Flanking Pads)
- 2 valves on North/South flanks in 2-team mode, 3 symmetric mid-sector valves in 3-team mode, and 4 diagonal flanking valves in 4-team mode.
- Triggering an active valve vents steam through floor pipes:
  - Grants the triggering team a **`2.5s` Rocket Surge**, blasting the cart away from their own door (through the central turntable onto a rival intact arm if needed, or straight down the active rival arm).
  - Emits a blast wave within `2.8m` of the cart to knock away nearby rivals, then places the valve on cooldown.

## 4. Arena Layout, Foundry-Railyard Visuals & Industrial Gauge HUD

- **Adaptive Topology**:
  - **2 Teams (`26m × 16m`)**: Straight East-West steel rail (`±11.5m`), West/East Blast Doors, 4 bumper pillars `(±5.5, ±3.8)`, and North/South Steam Valves `(0, ±6.0)`.
  - **3 Teams (`26m × 26m`)**: Central heavy steel turntable hub at `(0, 0)`, Y-shaped 120° radial steel rails (`10.5m` each), 3 Blast Doors, 3 mid-sector pillars, and 3 symmetric Steam Valves.
  - **4 Teams (`26m × 26m`)**: Central heavy steel turntable hub at `(0, 0)`, Cross (+) radial steel rails (`10.5m` each), 4 Blast Doors, 4 mid-diagonal pillars `(±4.2, ±4.2)`, and 4 diagonal Steam Valves `(±8.0, ±8.0)`.
- **Foundry-Railyard Visuals & Post-FX**:
  - Warm low-saturation heavy-foundry lighting (rusty ambient, tungsten key, amber furnace fill), sub-deck foundation, tall North foundry back wall with overhead pipes and cage lamps, a **3D Diegetic Industrial CRT Clock/Phase Monitor** displaying `MM:SS` and phase in amber `Terminal F4`, and official `vignette.gdshader` + `posterization.gdshader` post-FX.
- **Distinct Bottom-Center Industrial Gauge HUD**:
  - Keeps top-right 100% clear for `team-party`'s frameless HUD.
  - Hard-edged `0px`-corner charcoal-steel & amber bottom-center gauge: steel rail pressure needle bar in 2-team mode, or compact **Blast Door Status Strip** (`SAFE` / threat `%` / `OUT`) in 3–4 team mode, with CJK `FontVariation` fallback and frameless thick-outlined alerts.

## 5. Host-Authoritative Networking & 20 Hz Snapshot Sync

- **Host-Authoritative Simulation (`multiplayer.is_server()`)**:
  - Host computes all player positions/stuns/alive state, 2D cart position/velocity/branch/turntable angle/surge timer, shockwave telegraph/detonation, valve states, door breach states, and ranked scoring.
- **Input & Snapshot RPCs**:
  - Client uplink: lightweight input RPC (`move_dir: Vector2`, `action_pressed: bool`) plus reliable action RPC.
  - Host downlink (~20 Hz, `0.05s`): compact snapshot dictionary containing `cart_x`, `cart_pos`, `cart_vel`, `cart_vel_2d`, `cart_branch_team`, `cart_branch_dist`, `cart_angle`, `cart_reset_pause`, `door_alive`, `team_breaches`, `active_team_ids`, `surge_team`/`surge_timer`, `pulse_active`/`pulse_remaining`, `valves`, `phase`, `time_left`, `overtime`, and per-player `{pos, facing, stun, action_cd, alive}`.

## 6. `lobby-bots` AI Controller (`ai_controller.gd`)

Each bot switches dynamically across 3 micro-roles across 2, 3, and 4 teams:

1. **Valve Flanker**: When a Steam Valve is active and no teammate is closer, one designated bot sprints to capture/slam it (unless the cart is close to own Blast Door, in which case defend first).
2. **Cart Pusher / Rammer**: Defends own branch when threatened, drives the cart down an intact rival branch from the rear side, uses `Space` for Power Ram when no rival is in shove range, and retreats outside `3.6m` during the final `0.45s` of a Phase 2/3 Shockwave telegraph.
3. **Brawler / Blocker**: When an enemy contests the Push Aura or races toward an active valve, intercepts and shoves (`Space`) them off the track.

## 7. Module File Structure & Performance Redlines

```text
mods/bomb-cart/
├── mod.json                 # id: "bomb-cart", requires: ["mpm-core", "team-party"]
├── main.gd                  # _mod_init / _mod_ready, 2-4 team admission & scene registration
├── config.gd                # Balance constants, 4-team colors, adaptive 2/3/4-team geometry
├── official_minigame.gd     # Vanilla Minigame signal interface adapter
├── bomb_cart_game.gd        # Host-authoritative loop, 2-4 team turntable physics, post-FX & scoring
├── arena_meshes.gd          # Foundry railyard, 2/3/4-branch rails, turntable, 3D CRT monitor & cart
├── ai_controller.gd         # lobby-bots 2-4 team 3-role flanking/pushing/dodging AI
├── fx_pool.gd               # Pre-allocated spark/steam/pulse/breach FX pools
├── hud_ui.gd                # Bottom-center 0px industrial gauge, YOU marker & outlined 3-2-1-GO
├── team_support.gd          # Copied from mods/_shared/team-support/team_support.gd
├── self_test.gd             # --self-test headless 2/3/4-team logic & stress verification
└── README.md                # Mod documentation
```

### Performance & Contract Redlines (Aligned with [mod-development.md](mod-development.md))
- **Zero Runtime Allocations**: All spark, steam jet, shockwave, and door-breach effects use pre-built `mpm-core.create_fx_pool()` pools warmed up inside the camera frustum during the 3s prep phase.
- **Hot-Path Prohibitions**: No `get_property_list()`, `Mesh`/`StandardMaterial3D` instantiation, or `queue_free()` inside `_process` or `_physics_process`.
- **Headless & Lint Compliance**: Must pass `node scripts/mod-lint.mjs` (explicit types for `call()` / `get()` / `get_meta()`).

## 8. Development Milestones & Acceptance Checklist

| Milestone | Deliverables | Acceptance Criteria |
| --- | --- | --- |
| **M1: Skeleton & Arena** | `mod.json`, `main.gd`, `config.gd`, `arena_meshes.gd`, `max_teams: 2` admission | Passes `mpm-core` gating checks (locked in FFA / local couch / 3–4 teams, open in 2-team mode); clean rail bay & door meshes |
| **M2: Cart Physics, Valves & 3-Phase Loop** | `bomb_cart_game.gd` push aura, shove vs. Power Ram, Steam Valves, Phase 2 shockwave, Phase 3 overload | Headless verification of 0–40–60–75s transitions, instant KO breach, 10s Sudden Death & underdog compensation |
| **M3: Networking, HUD, FX & AI** | 20 Hz snapshot sync, `hud_ui.gd` tug-of-war bar, `fx_pool.gd` frustum warmup, `ai_controller.gd` | Bots capture flank valves, dodge shockwaves & contest the cart; 60 FPS stress test with zero node leaks |
| **M4: Tests, Packaging & Acceptance** | `self_test.gd`, `run_mac.sh` preview & cover screenshot, `scripts/pack-mod.mjs`, [catalog/mods.json](../../../catalog/mods.json) | `SELF_TEST_PASSED`, `npm run check:architecture` and `npm test` pass; Tier 3 Windows Steam multiplayer acceptance |
