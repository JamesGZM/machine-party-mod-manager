# Voltage Greed (`voltage-greed` / 高壓績效)

Close-up theatrical 2–8+ player push-your-luck industrial minigame (`both` mode: FFA + native [`team-party`](../team-party/README.md) + local couch) built on [`mpm-core`](../mpm-core/README.md) (`minigame_sdk` Hub v2 dynamic slot `>= 1000`).

## Gameplay

- **Admission (`both`, 2–8+ Players)**:
  - `mode_support = "both"`, `min_teams = 2`, `max_teams = 4`, `min_total_players = 2`, `min_players_per_team = 1`, `allow_local_couch = true`.
  - Runs natively in FFA, local couch, and `team-party` (2–4 teams), adapting seating and camera framing across 2–4P single-row and 5–8+P two-tier riser stages.
- **3 Escalating Rounds (`~55s`)**:
  - **Prep (3.0s)**: Opening `YOU` corner bracket tracks the local player alongside a `3-2-1-GO!` countdown while pre-allocated FX pools warm up in-frustum.
  - **Round 1 (`1.0×` KPI)**: Clean baseline rules with no random Coach event.
  - **Round 2 (`1.25×` KPI)**: Faster voltage climb + 1 mid-round Coach Industrial Event.
  - **Round 3 (`1.5×–2.0×` KPI)**: High-stakes comeback multiplier + 1 mid-round Coach Industrial Event.
- **Controls & Live-Only Sabotage**:
  - **Hold `Space` / `W` / `↑`**: Pull chair lever to farm unbanked KPI on an accelerating curve while pushing the shared transformer toward a hidden `[70%, 100%]` threshold.
  - **Release `Space`**: Bail out, drop the insulated visor, lock current round KPI, and isolate from detonation (cannot re-engage until the next round).
  - **Tap `S` / `↓` (1 charge/round, LIVE-ONLY)**: Usable **only while holding `Space`** (locked out once bailed). Instantly spikes transformer voltage by `+12%` and grants a `1.8s` `1.35×` personal KPI surge.
- **2-Life Execution & Coach Slacker Penalty**:
  - **1st Overload Fry (1 life left)**: Chars the player, blows 1 armrest fuse bulb, and wipes unbanked current-round KPI to `0`.
  - **2nd Overload Fry (0 lives left)**: Blows out the chair permanently (keeps previously banked total KPI). If `<= 1` survivor (FFA) or `<= 1` alive team (`team-party`) remains after Round 1 or 2, the match finishes early.
  - **Anti-Slacker Callout**: If all living players bail out before explosion, the Coach reprimands the lowest-KPI earner of the round (tie-broken by earliest bail), halving (`-50%`) their round score.
- **Coach Industrial Events (Rounds 2 & 3)**:
  - **False Alarm (`1.2s`)**: Strobe & klaxon bait while voltage rise briefly pauses.
  - **Glitching Meter (`1.5s`)**: Needle jitters and CRT scrambles to `ERR // ???` while true voltage keeps rising.
  - **Double Overtime (`2.5s`)**: Gold factory bell doubles KPI tick rate (`2.0×`).
- **Native `team-party` Synergy**:
  - **Parallel Circuit Resonance (`+20%`)**: Active whenever `>= 2` living teammates hold simultaneously, linked by team-colored arcs.
  - **Solo-Team Compensation (`+10%`)**: Granted automatically to 1-player teams or squads reduced to 1 living member.
  - **Kamikaze Sabotage**: One teammate banks early while another stays live to slam `S` and detonate greedy rivals.
- **Standalone Preview Hotkeys**: `[F2]` 4P FFA · `[F3]` 2v2 Team · `[F4]` 2v2v2v2 (8P Team) · `[F5]` 8P FFA · `[R]` Reset.

## Files

| File | Purpose |
| --- | --- |
| `mod.json` | Manifest (`id: "voltage-greed"`, `requires: ["mpm-core"]`) |
| `main.gd` | MPML v2 entry registering scripts & `"both"` admission into `mpm-core` |
| `official_minigame.gd` | Official `Minigame` signal/RPC lifecycle adapter |
| `config.gd` | Balance constants, 2–8P seating/camera geometry, team & player palette |
| `voltage_greed_game.gd` | Host-authoritative 3-round simulation, 2-life execution, events, post-FX & 20 Hz snapshots |
| `arena_meshes.gd` | Electric chair arc/riser, analog transformer & overhead CRT, Coach podium & procedural icon |
| `fx_pool.gd` | Pre-allocated spark/arc/char/blood FX pools with frustum warmup |
| `hud_ui.gd` | Opening `YOU` bracket, `3-2-1-GO!`, Coach banner, bottom-center 0px key legend & summary |
| `ai_controller.gd` | Archetype-driven AI (`Cautious Clerk`, `Greedy Gambler`, `Chaos Saboteur`) |
| `team_support.gd` | Synced from `mods/_shared/team-support/team_support.gd` |
| `self_test.gd` | Deterministic headless `--self-test`, `--smoke-test`, and `--capture-screenshot` staging |

## Local Testing

```bash
./mods/voltage-greed/run_mac.sh --self-test
./mods/voltage-greed/run_mac.sh --smoke-test
node scripts/mod-lint.mjs
node --test tests/mods/voltage-greed-team.test.mjs
./mods/voltage-greed/run_mac.sh --screenshot preview_4p.png --players=4
./mods/voltage-greed/run_mac.sh --screenshot preview_8p.png --teams=4 --per-team=2
```
