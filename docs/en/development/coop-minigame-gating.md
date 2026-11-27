# Co-op Minigame Design and Admission Gating

**English** · [简体中文](../../zh-CN/development/coop-minigame-gating.md) · [繁體中文](../../zh-TW/development/coop-minigame-gating.md)

This specification defines play-mode compatibility declarations (`both`, `team_only`, `ffa_only`), admission gating rules, and co-op versus minigame blueprints built on top of `mpm-core` and [team-party](../../../mods/team-party/README.md).

## 1. Background & Goals

With `team-party` providing 2–4 squad lobby assignment, vanilla minigame team hooks, and a shared team registry, first-party minigames can now implement native squad rules (`roller-carnival`, `bubble-blitz`, `spike-ring`). However, team-oriented co-op versus minigames introduce two requirements that survival brawlers did not have:

1. **Mixed mode compatibility**: Some minigames work well in both Free-For-All (FFA) and Team Party, whereas others (e.g., 2v2 tug-of-war, strict assembly-line division of labor, tethered pairs) make no sense—or cannot run cleanly—without active teams.
2. **Preventing unplayable draws**: Custom minigames register into `Globals.default_playlist` on lobby entry. Without admission filtering, a room in FFA or with an incompatible team count could still draw a team-only minigame.

Design goals:
- **Zero breakage for existing mods**: Mods that omit gating metadata default to `"both"` with no extra restrictions.
- **Never mutate `Globals.default_playlist` dynamically**: Keep `Globals.default_playlist` static and complete; filter dynamically at every consumption point instead.
- **Single source of truth**: Centralize eligibility evaluation in `mpm-core` ([minigame_sdk.gd](../../../mods/mpm-core/minigame_sdk.gd)) so the lobby list, official default rotation, Arcade, custom playlists, local couch play, and the CRT picker all follow identical rules.

## 2. Play-Mode Support Matrix (`mode_support`)

Every first-party minigame registering with `mpm-core` should declare its mode compatibility:

| `mode_support` | Target Design | Behavior in FFA | Behavior in Team Party | Examples |
| --- | --- | --- | --- | --- |
| `"both"` (default) | Playable solo or in squads | Independent scoring per player | Unlocks team colors, friendly-fire protection, and co-op perks (links, rescues) | `roller-carnival`, `bubble-blitz`, `spike-ring`, Resource Heist, Circuit Turf |
| `"team_only"` | Requires squad coordination or team-vs-team structure | **Blocked**: locked in lobby list; excluded from default/arcade pools | Eligible when `min_teams`, `max_teams`, and `min_players_per_team` are met | 2v2 Payload Tug-of-War, Overclocked Line, Tether Dash |
| `"ffa_only"` | Strictly solo competitive rounds | Eligible | **Blocked**: locked in lobby list; skipped when Team Party is active | Future solo-only deduction or survival rounds |

### Optional Mode: Temporary Round Squads (`auto_temp_teams`)

For team-structured minigames that should still appear in FFA lobbies (similar to *Fall Guys* team rounds or *Mario Party* 2v2 minigames):
- Declare `"mode_support": "both"` with `"auto_temp_teams": true`.
- When `team-party` is enabled, use the host's configured squads.
- When the lobby is in FFA and player count is eligible (e.g., even count or `>= 4`), form **temporary Red vs. Blue squads for that round only**, then return to individual scoring afterward.

## 3. Declarative Gating Contract in `mpm-core`

### Registration Extension

Extend `register_minigame(spec)` in [minigame_sdk.gd](../../../mods/mpm-core/minigame_sdk.gd) with an optional `admission` dictionary (all fields default safely when omitted):

```gdscript
"admission": {
	"mode_support": "both",       # "both" | "team_only" | "ffa_only"
	"auto_temp_teams": false,     # optional: form temporary teams in FFA lobbies
	"min_teams": 2,               # effective when team mode is active / required
	"max_teams": 4,               # e.g. 2 for 2-team tug-of-war
	"min_total_players": 2,       # total room players (including lobby-bots)
	"min_players_per_team": 1,    # e.g. 2 for tethered/2-player-carry mechanics
	"allow_local_couch": true,    # false if online-only or unsupported locally
	"custom_check": Callable(),   # optional pure escape-hatch predicate
}
```

### Unified Evaluator: `evaluate_minigame_eligibility(spec, context)`

`mpm-core` exposes one evaluator reading `Engine.get_meta("mpm_team_party")`, the current room roster (including `lobby-bots`), and local-couch mode, returning:

- `eligible: bool`: whether the minigame may enter the match playlist right now.
- `hard_blocked: bool`: whether a configuration/mode mismatch blocks adding the minigame in the lobby list.
- `soft_warning: bool`: whether a headcount requirement is not yet met (host may pre-select it in the lobby, but match start skips it if still unmet).
- `reason_key: String`: localized badge/tooltip key (`needs_team_mode`, `ffa_only`, `team_count_out_of_range`, `needs_more_players`, `needs_more_per_team`, `local_unsupported`).

## 4. Hard vs. Soft Gating & Lobby Game List UX (`override_playlist.gd`)

The Custom Playlist selector is managed by [override_playlist.gd](../../../mods/mpm-core/override_playlist.gd) (left "All Minigames" list, right "Selected" list).

### Display Policy: Greyed & Labeled, Not Hidden

Ineligible minigames should **remain visible** in the left "All Minigames" list rather than disappearing—otherwise players may assume a newly installed mod failed to load. Lock them with `MinigameListItem.set_inactive(true)` and append a concise localized tag (e.g., `Overclocked Line [Team Mode]`, `Payload Tug [2 Teams Only]`).

### Hard vs. Soft Separation

Hosts frequently configure playlists right after opening a room (while alone) before friends or bots join. Separating gates avoids blocking legitimate setup:

1. **Hard gates (locked in left list, cannot be added)**: configuration rules the host can change immediately.
   - `mode_support == "team_only"` while `team_party.enabled == false`.
   - `mode_support == "ffa_only"` while `team_party.enabled == true`.
   - Team mode is active, but configured `team_count` is outside `[min_teams, max_teams]`.
   - `allow_local_couch == false` in local couch mode.
2. **Soft gates (warning tag, allowed in right list)**: live headcount rules.
   - Total room players below `min_total_players`.
   - Active non-empty teams below `min_teams`, or smallest active team below `min_players_per_team`.
   - Hosts can pre-build playlists while waiting for players; `generate_session_playlist()` filters them out at launch if still unmet.

### Live Reactivity & Switching Back to FFA

1. **Live refresh**: [team_registry.gd](../../../mods/team-party/team_registry.gd) emits `team_party.state_changed` via [event_bus.gd](../../../mods/mpm-core/event_bus.gd) inside `publish_state()`. `override_playlist.gd` subscribes and refreshes lock states and badges immediately.
2. **Existing `team_only` selections when toggling back to FFA**: Keep them in the right list greyed out with `[Team Mode]` and skip them at match start (so casual mode toggles do not wipe the host's curated list). Meanwhile, `load_current_playlist()` and `_on_default_button_pressed()` only populate entries that pass hard gates.

## 5. Default Playlist, Arcade, Local Play & CRT Picker Filtering

To handle games present in `Globals.default_playlist` when current room settings do not qualify, **never remove entries from `Globals.default_playlist`**. Instead, filter via `evaluate_minigame_eligibility()` at all 4 consumption points:

1. **Online session generation ([override_game.gd](../../../mods/mpm-core/override_game.gd))**:
   - Filter entries in Official Default, Arcade, and Custom Playlist branches of `generate_session_playlist()`.
2. **Local couch session generation ([override_local_game.gd](../../../mods/mpm-core/override_local_game.gd))**:
   - Filter `generate_session_playlist()` identically so `team_only` or `allow_local_couch == false` games are excluded in local couch play.
3. **Lobby playlist UI ([override_playlist.gd](../../../mods/mpm-core/override_playlist.gd))**:
   - Gate `load_current_playlist()` and `_on_default_button_pressed()` and update left-list lock states.
4. **15-slot CRT picker ([override_picker.gd](../../../mods/mpm-core/override_picker.gd))**:
   - Skip ineligible custom minigames when building `dictionary_array_to_send` in `setup_minigame_pick_host()` so locked rounds never flash on the CRT without being selectable.

### Empty-Playlist Safeguard

If a host selects **only `team_only` minigames** in a Custom Playlist and then launches in FFA, filtering would yield an empty `minigames_shuffled` array. `generate_session_playlist()` must fall back to eligible entries from `Globals.default_playlist` so `session_minigame_list` is never empty.

## 6. Edge Cases & Planning Gaps

Implementations must cover these edge cases:

1. **Empty or asymmetric teams in `FREE` mode**:
   - Do not trust the `team_count` slider alone (e.g., 2 teams configured, but all players sit on Team 1 as `2v0`).
   - Evaluate **`active_team_count`** (teams with `>= 1` member) and **`min_active_team_size`**. A `2v0` room has only 1 active team and must not launch adversarial team rounds.
2. **Online host/client consistency**:
   - `generate_session_playlist()` runs authoritatively on the host (`multiplayer.is_server()`) and replicates via `setup_icons_from_data_rpc`.
   - Clients read the synced `team-party` state in the lobby so list lock badges match the host.
3. **Mid-match disconnects & bot removal**:
   - Even after passing lobby checks, disconnects can drop a squad to 1 or 0 players mid-round.
   - Every co-op minigame must implement two runtime fallbacks:
     - **Mechanic degradation**: Dual-carry or dual-switch props automatically lighten or allow solo activation if a squad drops to 1 alive player.
     - **Early team-victory settlement**: Trigger round completion and Squads scoring cleanly if only 1 active team has surviving players.
4. **Catalog & dependency declarations ([catalog/mods.json](../../../catalog/mods.json))**:
   - `team_only` mods **must** list both `mpm-core` and `team-party` in `requires` so the desktop manager installs `team-party` automatically.
   - `both` mods only require `mpm-core` and document optional `team-party` enhancements in their trilingual `detail` text.
5. **Shared Hub parity (`mods/_shared/minigame-hub/`)**:
   - `override_game.gd`, `override_local_game.gd`, `override_picker.gd`, and `override_playlist.gd` are shared hub overrides; after editing, run `node scripts/pack-mod.mjs --sync-shared` and verify with `npm run check:architecture`.
6. **Automated test coverage**:
   - Add tests covering `both`, `team_only`, `ffa_only`, `2v0` empty-team detection, default/arcade/custom filtering, and the empty-playlist fallback.

## 7. Co-op Versus Party Game Reference Blueprints

Five popular party-game archetypes adapted for Machine Party's industrial aesthetic and keyboard controls (`WASD` + `Space` / `S`):

| Archetype | Reference Titles | Recommended `mode_support` | Team Counts | Core Co-op & Versus Loop | Machine Party Industrial Adaptation |
| --- | --- | --- | --- | --- | --- |
| **Resource Heist & Carry** | *Party Animals* (Lollipop Factory), *Fall Guys* (Egg Scramble) | `"both"` | 2–4 teams | Split roles (carrier / defender / raider); heavy cores move faster with 2 carriers; steal from rival goals | **Core Heist**: Contest central batteries & 2-player heavy reactor cores |
| **Assembly Line Versus** | *Overcooked! 2* (Versus), *Mario Party* (Cake Factory) | `"team_only"` (or `auto_temp_teams`) | 2–4 teams | Fetch → process → ship pipeline; shared central material pit; completed orders sabotage the leading team | **Overclocked Line**: Shared scrap pit; deliveries reverse rival conveyors or drop junk |
| **Circuit Turf War** | *Splatoon* (Turf War), *Fall Guys* (Power Trip) | `"both"` | 2–4 teams | Tile painting for score; nearby teammates form arc links that paint swaths; high-voltage cells burst-paint | **Circuit Turf**: Sensor tiles flip to team color with teammate arc-link bursts |
| **Payload Tug / Rail Assault** | *Fall Guys* (Fall Ball), *Party Animals* (Fluffy Redemption) | `"team_only"` | 2–4 teams (adaptive straight / Y / Cross turntable rails) | Striker/defender positioning; push payload into rival Blast Doors before timer expires | **Bomb Cart (`bomb-cart`)**: Adaptive 2–4 team turntable rail assault |
| **Electromagnetic Tether** | *Chained Together*, *PICO PARK 2*, *Mario Party* (Handcar Havoc) | `"team_only"` | 2 per team (`min_players_per_team: 2`) | Teammates linked by an elastic tether must synchronize movement; tether trips rival squads | **Tether Dash**: Electrified squad tether across rotating arms & conveyors |
