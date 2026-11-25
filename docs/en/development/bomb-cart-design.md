# Bomb Cart Gameplay and Development Specification

**English** · [简体中文](../../zh-CN/development/bomb-cart-design.md) · [繁體中文](../../zh-TW/development/bomb-cart-design.md)

This specification defines the complete gameplay rules, arena geometry, network synchronization, AI behavior, and development milestones for **`bomb-cart` (Bomb Cart)**, a 2-team-only rail tug-of-war minigame mod built on `mpm-core` and `team-party`.

## 1. Mod Positioning & Admission Contract

- **Mod ID**: `bomb-cart` (`category: "game"`)
- **Dependencies**: `requires: ["mpm-core", "team-party"]` (declared in both [catalog/mods.json](../../../catalog/mods.json) and `mod.json`)
- **Slot Registration**: Dynamic slot (`>= 1000`) via `mpm-core`'s `register_minigame()`, following the [First-party mod development specification](mod-development.md) and [Co-op minigame design and admission gating](coop-minigame-gating.md).
- **Admission Contract (Strict 2-Team `"team_only"`)**:

```gdscript
"admission": {
	"mode_support": "team_only",
	"min_teams": 2,
	"max_teams": 2,
	"min_total_players": 2,
	"min_players_per_team": 1,
	"allow_local_couch": false,
}
```

- **Gating Behavior**:
  - `bomb-cart` is the first mod exercising the strict `max_teams: 2` (`[2 Teams Only]`) hard gate in the lobby playlist when 3–4 teams are configured in `team-party`.
  - When `team-party` is disabled (FFA) or in local couch mode, the lobby left-hand list grays out and locks the entry (`[Needs Team Mode]` / `[Online Only]`), and excludes it from the Default playlist, Arcade pool, and 15-slot CRT picker.
- **Asymmetric / Disconnect Underdog Fallback**:
  - Allows asymmetric starts (e.g., `1v2`) and mid-match disconnects. When alive team sizes differ, the smaller team receives proportional push-weight compensation (`clampf(larger / smaller, 1.0, 1.5)`).
  - If only one active team retains online members, immediate team victory and synchronized Squads scoring trigger.

## 2. Core Gameplay Loop, 3-Phase Escalation & Victory Rules

The match runs **Host-Authoritative** (`multiplayer.is_server()`) for **3s Prep + 75s Match** (plus an optional **10s Sudden Death Overtime** if tied within `|cart_x| <= 0.15m` at `t = 75s`):

1. **Prep Phase (3s)**:
   - Team 1 (Red) spawns in formation in front of the West Blast Door (`-11.5m`); Team 2 (Blue) spawns in front of the East Blast Door (`+11.5m`).
   - Camera frames the central steel rail, the Bomb Cart at `x = 0`, and the North/South Steam Valves while the HUD displays team colors and objective cues.
2. **Phase 1: Standard Push (0–40s)**:
   - Base cart push speed multiplier `1.0×`; one Steam Valve (alternating North and South) charges and activates every `14s` for flanking control.
3. **Phase 2: Fuse Ignited (40–60s)**:
   - Base cart push speed rises to `1.35×` to break midfield stalemates.
   - Every `8s`, the Bomb Cart projects a **`1.2s` red danger ring (`3.2m` radius)** before emitting a **Shockwave Pulse** that knocks back players caught inside (`0.35s` stagger).
4. **Phase 3: Critical Overload (60–75s)**:
   - Base cart push speed rises to `1.75×`, **both** North and South Steam Valves activate simultaneously on a `10s` cycle, and the warhead flashes rapid critical red with alarm cues for dramatic late-game comebacks.
5. **Victory & Squads Scoring**:
   - **Blast Door Breach (Instant KO)**: Pushing the Bomb Cart into the enemy Blast Door triggers immediate detonation victory—reaching `x >= +11.5m` (Blue Blast Door) awards Red the win; reaching `x <= -11.5m` (Red Blast Door) awards Blue the win.
   - **Timer Detonation (75s)**: If neither door is breached when time expires, the bomb detonates in place—whichever half it sits on loses (`x > +0.15m` Red wins; `x < -0.15m` Blue wins).
   - **Sudden Death Overtime (10s)**: If `|cart_x| <= 0.15m` at `t = 75s`, enter a 10s Sudden Death where the first team to push past `±0.6m` wins (falling back to peak progress `max_abs_push` if still tied).
   - Final scores sync through `team-party` Squads scoring back to the room leaderboard.

## 3. Controls, Push Physics, Power Ram & Steam Boost Valves

Follows Machine Party's minimal 2-input keyboard scheme (`WASD / Arrows` + `Space`):

| Input | Behavior |
| --- | --- |
| `WASD` / Arrows | Move and steer (`6.6 m/s`). Stepping inside the cart's **`2.6m` Push Aura** automatically applies push force toward the enemy Blast Door. The aura shifts color dynamically (Red / Blue / Contested yellow sparks). Net team advantage beyond `+2` follows diminishing returns so 4v4 stays a tug-of-war instead of an instant slide. |
| `Space` (shared `0.95s` cooldown, context-sensitive priority) | 1. **Industrial Shove**: If an enemy is within the `2.1m` front cone, knocks them out of the push zone with `0.45s` stun and `8.5 m/s` impulse; **zero friendly fire** via `team_support.are_teammates`.<br>2. **Power Ram**: Otherwise, if within `2.4m` of the Bomb Cart, slams the cart for an immediate directional velocity burst + metal spark VFX.<br>3. **Quick Valve Slam**: Otherwise, if standing on an active Steam Valve pad, triggers the valve immediately (standing on an active pad for `0.6s` also auto-triggers it). |

### Steam Boost Valves (North & South Flanks)
- Two high-pressure Steam Valve pads sit on the North and South flanks, glowing with a pressure ring and pipe pre-charge when active.
- Triggering an active valve vents steam through floor pipes into the rail:
  - Grants the triggering team a **`2.5s` Rocket Surge**, strongly accelerating the cart toward the enemy Blast Door.
  - Emits a blast wave within `2.8m` of the cart to knock away nearby rivals, then places the valve on cooldown.

## 4. Arena Layout & Visual Readability (`26m × 16m` Factory Rail Bay)

- **Camera & Bounds**: Elevated 3/4 angled camera framing West-to-East tug-of-war (`X: -13m..+13m`, `Z: -8m..+8m`), enclosed by industrial guardrails.
- **Central Heavy Steel Rail (`X: -11.5m..+11.5m`)**:
  - Floor distance chevrons at `25%`, `50%` (midfield), and `75%`, plus dynamic team-colored track LEDs.
- **West & East Blast Doors**:
  - West Red Blast Door (`-11.5m`) and East Blue Blast Door (`+11.5m`) equipped with warning beacons that flash faster when the cart closes within `3.5m`.
- **Obstacles & Flanking Lanes**:
  - 4 symmetric industrial bumper pillars at `(±5.5, ±3.8)` carve out the central rail lane and the North `(0, -6.0)` / South `(0, +6.0)` valve flank routes.
- **Bomb Cart Visuals**:
  - Heavy steel rail chassis, wheels rotating with `cart_vel`, ticking warhead cylinder with phase-driven emissive glow, ground Push Aura, and Shockwave telegraph ring.

## 5. Host-Authoritative Networking & 20 Hz Snapshot Sync

- **Host-Authoritative Simulation (`multiplayer.is_server()`)**:
  - Host computes all player positions/stuns, cart position/velocity/surge timer, shockwave telegraph/detonation, valve states, and match outcome.
- **Input & Snapshot RPCs**:
  - Client uplink: lightweight input RPC (`move_dir: Vector2`, `action_pressed: bool`).
  - Host downlink (~20 Hz, `0.05s`): compact snapshot dictionary containing `cart_x`, `cart_vel`, `cart_owner`, `surge_team`, `surge_timer`, `pulse_state` / `pulse_timer`, `valve_states` (North/South), `phase`, `time_left`, `overtime`, and per-player `{pos, yaw, stun, ram_cd}`.

## 6. `lobby-bots` AI Controller (`ai_controller.gd`)

Each bot switches dynamically across 3 micro-roles so 2v2–4v4 bot matches exhibit flanking, pushing, and counter-shoving:

1. **Valve Flanker**: When a Steam Valve is active and no teammate is closer, one designated bot sprints to capture/slam it (unless the cart is within `3.0m` of own Blast Door, in which case defend first).
2. **Cart Pusher / Rammer**: Enters the cart's Push Aura on the friendly rear side to push toward the enemy door, using `Space` for Power Ram when no rival is in shove range; retreats outside `3.4m` during the final `0.45s` of a Phase 2/3 Shockwave telegraph.
3. **Brawler / Blocker**: When an enemy contests the Push Aura or races toward an active valve, intercepts and shoves (`Space`) them off the track.

## 7. Module File Structure & Performance Redlines

```text
mods/bomb-cart/
├── mod.json                 # id: "bomb-cart", requires: ["mpm-core", "team-party"]
├── main.gd                  # _mod_init / _mod_ready, max_teams: 2 admission & scene override
├── config.gd                # Balance constants, colors, phase timings & arena geometry helpers
├── official_minigame.gd     # Vanilla Minigame signal interface adapter
├── bomb_cart_game.gd        # Host-authoritative loop, cart physics, valves, pulses & scoring
├── arena_meshes.gd          # Rail bay, blast doors, pillars, steam valves & cart meshes
├── ai_controller.gd         # lobby-bots 3-role flanking/pushing/dodging AI
├── fx_pool.gd               # mpm-core.create_fx_pool() spark/steam/pulse/breach pools
├── hud_ui.gd                # Top tug-of-war bar (RED [===💣===] BLUE), phase banners & timer
├── team_support.gd          # Copied from mods/_shared/team-support/team_support.gd
├── self_test.gd             # --self-test headless logic & edge-case verification
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
