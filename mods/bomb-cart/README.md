# Bomb Cart (`bomb-cart` / 炸彈推車)

Adaptive 2–4 team (`team_only`, `min_teams: 2`, `max_teams: 4`) 75-second industrial foundry-railyard assault minigame built on [`mpm-core`](../mpm-core/README.md) (`minigame_sdk` Hub v2 dynamic slot `>= 1000`) and [`team-party`](../team-party/README.md).

## Gameplay

- **Admission (`team_only`, 2–4 teams)**: Requires Team Party active in online mode (`>= 2` total players, `>= 1` per team). Supports `2v2`, `4v4`, `2v2v2`, `2v2v2v2`, and asymmetric starts (`1v2`) with proportional underdog push-weight compensation (`clampf(larger / smaller, 1.0, 1.5)`). Locked in FFA and local couch mode.
- **Adaptive Rail Arena**:
  - **2 Teams**: Classic `26m × 16m` East-West straight steel rail (`±11.5m`) with West/East Blast Doors, North/South Steam Valves, and 4 buffer pillars.
  - **3 Teams**: `26m × 26m` arena with a central heavy steel turntable hub `(0, 0)`, Y-shaped 120° radial steel rails (`10.5m` each), 3 Blast Doors, and 3 symmetric Steam Valves.
  - **4 Teams**: `26m × 26m` arena with a central heavy steel turntable hub `(0, 0)`, Cross (+) radial steel rails (`10.5m` each), 4 Blast Doors, and 4 diagonal Steam Valves.
- **3-Phase Escalation**:
  - **Phase 1: Standard Push (0–40s)**: `1.0×` base push speed. Steam Valves cycle every `14s`.
  - **Phase 2: Fuse Ignited (40–60s)**: `1.35×` base push speed. Every `8s`, the Bomb Cart projects a `1.2s` warning ring (`3.2m` radius) before emitting a Shockwave Pulse (`0.35s` stun + `9.0 m/s` knockback).
  - **Phase 3: Critical Overload (60–75s)**: `1.75×` base push speed. All Steam Valves activate simultaneously on a `10s` cycle.
- **Victory & Sudden Death**:
  - **2 Teams**: Blast Door breach at `±11.5m` awards Instant KO; at `75s`, half-field position (`±0.15m`) decides; ties enter 10s Sudden Death (`±0.6m`).
  - **3–4 Teams**: Breaching a team's Blast Door (`10.5m`) eliminates that team immediately (updating `team-party`'s top-right HUD) and resets the cart to the central turntable (`1.2s` pause) until 1 intact team remains. At `75s`, intact teams beat breached teams (ranked by safety & breach credit); dead-center ties enter 10s Sudden Death (`> 0.8m` onto any intact rival arm).
- **Controls**:
  - `WASD` / Arrow keys: Move (`6.6 m/s`) and push inside the cart's `2.6m` Push Aura.
  - `Space` (`0.95s` cooldown, context-sensitive):
    1. **Industrial Shove** (`2.1m` front cone, `0.45s` stun + `8.5 m/s` impulse, zero friendly fire).
    2. **Power Ram** (`2.4m` cart range, `+3.8 m/s` directional cart impulse).
    3. **Quick Valve Slam** (`1.6m` active valve pad, instant `2.5s` Rocket Surge + `2.8m` cart blast wave).
- **Standalone Preview Hotkeys**: `[F2]` 2v2 · `[F3]` 2v2v2 · `[F4]` 2v2v2v2 · `[F5]` 4v4 · `[R]` Reset (CLI: `--teams=2..4 --per-team=1..4`).

## Files

| File | Purpose |
| --- | --- |
| `mod.json` | Manifest (`id: "bomb-cart"`, `requires: ["mpm-core", "team-party"]`) |
| `main.gd` | MPML v2 entry, registers scripts & 2–4 team `team_only` admission into `mpm-core` |
| `official_minigame.gd` | Official `Minigame` signal/RPC lifecycle wrapper |
| `config.gd` | Balance constants, 4-team colors, adaptive 2/3/4-team rail & valve geometry, oriented cart collision |
| `bomb_cart_game.gd` | Host-authoritative simulation, 2–4 team turntable physics, door breach elimination, post-FX & 20 Hz snapshots |
| `arena_meshes.gd` | Warm foundry-railyard arena, 2/3/4-branch rails & turntable hub, 3D diegetic CRT monitor, cart & player rigs |
| `fx_pool.gd` | Pre-allocated FX pools with frustum warmup |
| `hud_ui.gd` | Bottom-center 0px-radius industrial gauge (2-team rail bar / 3–4 team door status strip), YOU marker & outlined 3-2-1-GO |
| `ai_controller.gd` | 2–4 team 3-role flanking/pushing/dodging AI |
| `team_support.gd` | Synced from `mods/_shared/team-support/team_support.gd` |
| `self_test.gd` | Headless `--self-test` verification (2-team, sparse, 3-team, 4-team & AI stress sims) |

## Local Testing

```bash
./mods/bomb-cart/run_mac.sh --self-test
node scripts/mod-lint.mjs
node --test tests/mods/bomb-cart-team.test.mjs
./mods/bomb-cart/run_mac.sh --screenshot /tmp/bc_4v4.png --teams=2 --per-team=4
./mods/bomb-cart/run_mac.sh --screenshot /tmp/bc_4t.png --teams=4 --per-team=2
```
