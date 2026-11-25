# Bomb Cart (`bomb-cart` / 炸彈推車)

Strict 2-team (`team_only`, `max_teams: 2`) 75-second industrial rail tug-of-war minigame built on [`mpm-core`](../mpm-core/README.md) (`minigame_sdk` Hub v2 dynamic slot `>= 1000`) and [`team-party`](../team-party/README.md).

## Gameplay

- **Admission (`team_only`, `max_teams: 2`)**: Requires Team Party active in 2-team online mode (`>= 2` total players, `>= 1` per team). Locked in FFA, local couch mode, and 3–4 team rooms. Supports asymmetric starts (`1v2`) and mid-match disconnects via proportional underdog push-weight compensation (`clampf(larger / smaller, 1.0, 1.5)`).
- **Phase 1: Standard Push (0–40s)**: `1.0×` base push speed. North and South Steam Valves alternate every `14s`.
- **Phase 2: Fuse Ignited (40–60s)**: `1.35×` base push speed. Every `8s`, the Bomb Cart projects a `1.2s` warning ring (`3.2m` radius) before emitting a Shockwave Pulse (`0.35s` stun + `9.0 m/s` knockback).
- **Phase 3: Critical Overload (60–75s)**: `1.75×` base push speed. Both North and South Steam Valves activate simultaneously on a `10s` cycle.
- **Victory & Sudden Death**:
  - **Blast Door Breach (Instant KO)**: Reaching `+11.5m` (Blue Blast Door) awards Red an instant win; reaching `-11.5m` (Red Blast Door) awards Blue an instant win.
  - **Timer Detonation (75s)**: If `cart_x > +0.15m`, Red wins; if `cart_x < -0.15m`, Blue wins.
  - **Sudden Death Overtime (10s)**: If `|cart_x| <= 0.15m` at `75s`, enter 10s Sudden Death where pushing past `±0.6m` wins immediately (falling back to peak progress `max_abs_push`).
- **Controls**:
  - `WASD` / Arrow keys: Move (`6.6 m/s`) and push inside the cart's `2.6m` Push Aura.
  - `Space` (`0.95s` cooldown, context-sensitive):
    1. **Industrial Shove** (`2.1m` front cone, `0.45s` stun + `8.5 m/s` impulse, zero friendly fire).
    2. **Power Ram** (`2.4m` cart range, `+3.8 m/s` directional cart impulse).
    3. **Quick Valve Slam** (`1.6m` active valve pad, instant `2.5s` Rocket Surge + `2.8m` cart blast wave).

## Files

| File | Purpose |
| --- | --- |
| `mod.json` | Manifest (`id: "bomb-cart"`, `requires: ["mpm-core", "team-party"]`) |
| `main.gd` | MPML v2 entry, registers scripts & strict 2-team `team_only` admission into `mpm-core` |
| `official_minigame.gd` | Official `Minigame` signal/RPC lifecycle wrapper |
| `config.gd` | Balance constants, colors, phase multipliers, underdog weight & arena collision |
| `bomb_cart_game.gd` | Host-authoritative simulation, 20 Hz snapshots, valves, shockwaves & `team_support` scoring |
| `arena_meshes.gd` | 26m × 16m rail bay, blast doors, pillars, steam valves, cart & player meshes |
| `fx_pool.gd` | Pre-allocated FX pools with frustum warmup |
| `hud_ui.gd` | Top tug-of-war bar, timer, phase badge & surge indicator |
| `ai_controller.gd` | 3-role flanking/pushing/dodging AI |
| `team_support.gd` | Synced from `mods/_shared/team-support/team_support.gd` |
| `self_test.gd` | Headless `--self-test` verification |

## Local Testing

```bash
./mods/bomb-cart/run_mac.sh --self-test
node scripts/mod-lint.mjs
node --test tests/mods/bomb-cart-team.test.mjs
```
