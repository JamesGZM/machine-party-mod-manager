<div align="center">

<img src="apps/desktop/src-tauri/icons/128x128@2x.png" width="80" alt="Machine Party Mod Manager icon">

# Machine Party Mod Manager

### One-click mod management for Machine Party.

Browse hand-curated mods for [Machine Party](https://store.steampowered.com/app/4108000/Machine_Party/), compare versions per Steam copy, and install or restore cleanly from one desktop window.

<p align="center">
  <a href="https://github.com/JamesGZM/machine-party-mod-manager/actions/workflows/check.yml"><img src="https://img.shields.io/github/actions/workflow/status/JamesGZM/machine-party-mod-manager/check.yml?branch=main&amp;style=flat-square&amp;label=checks" height="24" alt="Source checks"></a>
  <a href="https://github.com/JamesGZM/machine-party-mod-manager/releases/latest"><img src="https://img.shields.io/github/v/release/JamesGZM/machine-party-mod-manager?style=flat-square&amp;label=release&amp;color=C99A49" height="24" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/JamesGZM/machine-party-mod-manager?style=flat-square&amp;color=64748B" height="24" alt="License: GPL-3.0-only"></a>
</p>

<p align="center">
  <a href="#download"><img src="https://img.shields.io/badge/Windows-x64-D99A24?style=flat-square" height="24" alt="Windows: x64"></a>
  <a href="#catalogued-mods"><img src="https://img.shields.io/badge/Steam-Machine%20Party%20v2.1.2-7A2431?style=flat-square" height="24" alt="Steam: Machine Party v2.1.2"></a>
</p>

**[Download](#download)** · [Getting started](#getting-started) · [Documentation](docs/en/README.md) · [Changelog](CHANGELOG.md)

**English** · [简体中文](docs/readme/README.zh-CN.md) · [繁體中文](docs/readme/README.zh-TW.md)

</div>

<p align="center">
  <img src="docs/images/screenshot-catalog.png" width="100%" alt="Mod catalog with version and category tags">
</p>

<p align="center"><sub>The catalog shows each mod’s version, category, live-counted status &amp; category filters, and batch mode.</sub></p>

## At a glance

| Curated mod catalog | Verified backups & restore | Mirror access & signed updates |
| --- | --- | --- |
| Search mod titles in Simplified Chinese, Traditional Chinese and English across all catalogued mods. | Checks running processes, game fingerprints and mutual-exclusion conflicts before editing files, keeping per-copy backups for offline uninstall. | Syncs the online catalog and approved packages via the project's Cloudflare Worker without needing GitHub; silent signed app updates include release notes. |

Automatic Steam detection · Offline cache & restore · Trilingual UI (简体中文 / 繁體中文 / English)

## Download

Download builds directly from the project mirror below or from [GitHub Releases](https://github.com/JamesGZM/machine-party-mod-manager/releases/latest).

| Platform | Architecture | Download | Notes |
| --- | --- | --- | --- |
| Windows | x64 | [Stable v0.2.5 (`setup.exe`)](https://machineparty.ailaogong.men/v1/app-downloads/0.2.5/setup.exe) | NSIS installer, signed in-app updates |

Run the Windows x64 NSIS installer.

Installed Windows clients verify the updater signature before installing.

## Future plans

Machine Party is available on Windows. macOS support is planned for a future release.

## Getting started

1. Launch the manager — it automatically locates your Steam copy of *Machine Party* (App ID `4108000`), or lets you pick a game folder manually in Settings.
2. Browse or search mods across all three languages; open any entry to check multiplayer requirements, conflicts, supported game versions and the author's repository.
3. Select **Install**. If the game is running, save your progress and choose **Close game and continue**. The manager verifies the package and backs up the files before applying it.
4. Filter by status (**All**, **Installed**, **Not installed**, **Updates**) or category (**Expansion**, **Game**, **Tool**, **Graphics**), enter **Batch** mode to install, update or uninstall multiple mods at once, or click the top-right gear icon to open **Settings** (language, game folder, built-in loader, Steam restore and app updates).

## The desktop app

| Settings modal | In-app update prompt |
| --- | --- |
| ![Settings modal](docs/images/screenshot-settings.png) | ![In-app update prompt](docs/images/screenshot-update.png) |

**v0.2.5** · Streamlined top-bar layout · Live-counted status & category filters · Batch mode · Settings modal (built-in loader & Steam restore)

The update prompt illustrates a simulated upgrade from 0.1.2-11 to 0.1.2-12.

## Catalogued mods

The table lists the versions in this repository’s [catalog](catalog/mods.json). The manager offers them after the corresponding catalog revision is published.

| Mod | Version | Summary | Adapter & `v2.1.2` status |
| --- | --- | --- | --- |
| [Overtime](https://github.com/DarkJadeStone/MachineParty-Overtime) | `v1.7` | Play online or locally with up to eight players | Author CLI payload → MPML |
| [MachineParty+](https://github.com/Ghostx10742/MachineParty-Plus) | `v2.1.0` | Public lobbies, voice chat and text chat | Native MPML |
| [Roller Carnival](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/roller-carnival) | `v0.1.12` | Mechanical carnival dodge minigame | Native MPML |
| [Lobby Bots](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/lobby-bots) | `v0.2.2` | Add or remove ready bots in online rooms. | Native MPML |
| [Standalone HD](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/standalone-hd) | `v0.1.2` | Sharper 3D rendering with the existing window and HUD layout | Native MPML |
| [Player Spotlight](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/player-spotlight) | `v0.1.1` | Local-only overhead industrial spotlight on your own character across 3D minigames | Native MPML |
| [Bubble Blitz](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/bubble-blitz) | `v0.1.6` | Fast 3-HP hybrid water-bubble arena across 4 randomized maps | Native MPML |
| [Spike Ring](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/spike-ring) | `v0.1.4` | 60s circular pit survival: wall-mounted gapped lasers, saws, floor spikes, shrinking ring & visible airdrops | Native MPML |
| [Team Party](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/team-party) | `v0.1.1` | Room-level 2-4 team setup & chair swapping, vanilla minigame hooks, and shared team registry API | Native MPML |
| [Core Heist](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/core-heist) | `v0.1.1` | Team-only 75s 2-4 squad energy heist with dual-team Core resonance, vault raids, and Overdrive steal bonuses | Native MPML |
| [Bomb Cart](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/bomb-cart) | `v0.1.1` | 2-4 team 75s adaptive rail assault (straight / Y / Cross turntable) with Power Ram, Steam Valve Rocket Surges, Shockwave Pulses, and Sudden Death | Native MPML |
| [Voltage Greed](https://github.com/JamesGZM/machine-party-mod-manager/tree/main/mods/voltage-greed) | `v0.1.0` | 3-round close-up electric-chair push-your-luck (2-8+P, FFA & team-party): hold to farm KPI, release to bank, live-only S +12% kick, factory monitor slacker penalty & industrial events | Native MPML (pending Windows check) |

See [candidate mods and inclusion rules](docs/en/catalog/mods.md) for acceptance checklists, upstream licensing notes and conflict groups.

## Release notes

**v0.2.7** · Adds **Bomb Cart (`v0.1.0`)** (strict 2-team rail tug-of-war) and **Core Heist (`v0.1.0`)** (2–4 team energy heist) to the verified stable catalog, backed by `mpm-core` (`v0.1.1`) minigame admission gating and `team-party` (`v0.1.1`). [Full changelog](CHANGELOG.md).

## Documentation

| Guide | Purpose |
| --- | --- |
| [Product requirements](docs/en/requirements.md) | Player flows, catalog order, search and acceptance criteria |
| [Current architecture](docs/en/architecture/README.md) | Components, Steam detection, catalog, installs and ADRs |
| [Development guide](docs/en/development/README.md) | Setup, layout, commands and verification |
| [Mod development specification](docs/en/development/mod-development.md) | Authoring, testing, catalog integration and deterministic R2 packaging |
| [Releasing](docs/en/development/releasing.md) | Signed desktop updates, release notes and release workflow |
| [Candidate mods and inclusion](docs/en/catalog/mods.md) | Game baseline, candidates, licences and the acceptance checklist |
| [Catalog delivery](docs/en/catalog/delivery.md) | Worker catalog, owner-approved publishing and mainland China acceptance (planned) |
| [UI design](docs/en/ui-design.md) | Layout, cards, settings, dialogs and planned flows |

All guides: [docs](docs/README.md).

## Privacy

The manager has no telemetry or analytics. Chosen game paths (`game-path.json`), per-copy install records (`installations.json`), package caches and backups stay strictly on disk. Network requests only reach the project's Worker endpoints for the online catalog, approved packages and signed app updates. Read [SECURITY.md](SECURITY.md) before sharing diagnostics.

## Contributing

Recommend a mod or submit a new version with the [mod submission form](https://github.com/JamesGZM/machine-party-mod-manager/issues/new?template=mod-submission.yml). For bugs, features and code, read [CONTRIBUTING.md](CONTRIBUTING.md). Coding agents follow [AGENTS.md](AGENTS.md). Get help through [SUPPORT.md](SUPPORT.md) and report vulnerabilities privately via [SECURITY.md](SECURITY.md).

## License

The manager is licensed under the [GNU General Public License v3.0 only](LICENSE) (SPDX `GPL-3.0-only`). Official builds are free.

Machine Party Mod Manager is a community project and is not affiliated with the game's developer. The game, third-party mods and cover images belong to their respective owners and keep their own licences; authors, versions and sources are shown on each entry. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Acknowledgements

- Community mod authors: [DarkJadeStone (Overtime)](https://github.com/DarkJadeStone/MachineParty-Overtime), [Ghostx10742 (MachineParty+)](https://github.com/Ghostx10742/MachineParty-Plus), [Lnksoul (Broadcast 8P Freecam)](https://github.com/Lnksoul/MachineParty_Broadcast8P_Freecam_Patcher), [Binary1936 (eight-player mod)](https://github.com/Binary1936/machine-party-8p) and [Krunk-theduck (MPML)](https://github.com/Krunk-theduck/MachinePartyModLoader).
- [Tauri](https://tauri.app/) and the open-source Rust and JavaScript dependencies listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
