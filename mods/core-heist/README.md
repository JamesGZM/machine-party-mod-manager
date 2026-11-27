# Core Heist (`core-heist` / 能源搶奪戰)

Team-only 75-second industrial energy heist minigame built on [`mpm-core`](../mpm-core/README.md) (`minigame_sdk` Hub v2 dynamic slot `>= 1000`, `mode_support = "team_only"`) and [`team-party`](../team-party/README.md).

## Gameplay

- **Admission (`team_only`)**: Requires Team Party active (`2–4` teams, `>= 2` total players, online multiplayer). Automatically locked with `[需組隊]` / `[Team Mode]` in FFA and `[僅連線]` / `[Online Only]` in local couch mode, and supports asymmetric teams (e.g. `1v1`, `1v2`).
- **Phase 1 (0–45s)**: Central reactor dispenser & two opposing conveyor belts output Standard Batteries (`+1`, `1.0x` speed) and Gold High-Voltage Batteries (`+3`, `0.88x` speed). Depositing into your team's furnace locks them for `3.0s` (magnetic shield); unlocked enemy batteries can be stolen.
- **Phase 2 (45–60s)**: Heavy Reactor Core (`+5`, permanently locked once deposited) drops at `45s` (`2s` warning). Solo carry is `0.55x` speed; having a non-stunned teammate within `2.6m` triggers **Dual-Team Electromagnetic Resonance** (`1.15x` speed + shove drop immunity + team beam). Single-member teams automatically receive a `0.85x` solo-team fallback.
- **Phase 3 (60–75s Overdrive)**: Spawn rate doubles, a second Heavy Core drops at `62s`, and any battery stolen from an enemy vault and deposited into your own grants a `+1` Steal Bonus.
- **Controls**:
  - `WASD` / Arrow keys: Move & auto-pickup loose or unlocked enemy vault batteries.
  - `Space`: Shove enemies (`0.45s` stun + battery drop, zero friendly fire) when empty-handed; throw/pass battery `2.5m` forward when carrying.

## Files

| File | Purpose |
| --- | --- |
| `mod.json` | Manifest (`id: "core-heist"`, `requires: ["mpm-core", "team-party"]`) |
| `main.gd` | MPML v2 entry, registers scripts & `team_only` admission into `mpm-core` |
| `official_minigame.gd` | Official `Minigame` signal/RPC lifecycle wrapper |
| `config.gd` | Phase timings, 2–4 team arena geometry, 32-cell pool scaling & combat constants |
| `arena_meshes.gd` | Warm industrial 2–4 team arena (concrete/brushed-steel/cast-iron/brick PBR contrast), vanilla PCK props & grime decals, 3D CRT monitor, vaults, player rigs & icon |
| `fx_pool.gd` | Pre-allocated FX pools via `mpm-core.create_fx_pool()`, scorch Decal, flash light & ambient dust mote pools with warmup |
| `hud_ui.gd` | Diegetic-first HUD: frameless top-left scores, opening YOU marker, 3-2-1-GO countdown & standalone CRT summary |
| `ai_controller.gd` | 4-state co-op AI (Escort, Carrier, Defender, Collector/Raider) |
| `core_heist_game.gd` | Server-authoritative simulation, indoor SpotLight pools/SSAO/depth fog, Post-FX, 20 Hz snapshots & `team_support` scoring |
| `team_support.gd` | Synced from `mods/_shared/team-support/team_support.gd` |
| `self_test.gd` | Tier-0 `--self-test`, `--smoke-test`, and `--capture-screenshot` staging |

## Local Testing

```bash
./mods/core-heist/run_mac.sh --self-test
./mods/core-heist/run_mac.sh --smoke-test
./mods/core-heist/run_mac.sh --screenshot preview_2v2v2v2.png --teams=4 --per-team=2
./mods/core-heist/run_mac.sh --screenshot preview_4v4.png --teams=2 --per-team=4
node --test tests/mods/core-heist-team.test.mjs
```

Standalone hotkeys: `[F2]` 2v2, `[F3]` 2v2v2, `[F4]` 2v2v2v2, `[F5]` 4v4, `[R]` Restart.
