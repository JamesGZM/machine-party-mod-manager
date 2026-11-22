# Changelog

**English** · [简体中文](docs/zh-CN/CHANGELOG.md) · [繁體中文](docs/zh-TW/CHANGELOG.md)

Notable changes for players and contributors. Versions follow the desktop app version.

## 0.2.5 — unreleased

- Adds an **Actions** menu to the left of the catalog search box with **Install selected**, **Update selected** and **Uninstall selected**. Every catalog card now has a persistent checkbox keyed by mod id: tick the cards first, then choose an action. Menu badges show how many of the *ticked* cards match each operation, updated live. Nothing is ever run on unticked or ineligible cards, and an empty selection shows a friendly hint instead of running anything.
- A confirmation dialog lists the exact mods about to be processed (with stronger wording for uninstall) and reports any ticked cards filtered out as ineligible. Execution reuses the existing single-mod commands serially, with a fresh eligibility and game-closed check before every write, a rescan after failures, a per-mod progress dialog and a succeeded / failed / skipped summary. Successfully processed mods are unticked; failed and skipped ones stay selected for a one-click retry.
- The button and dropdown now form one interaction area: a transparent bridge covers the gap, hover and click stay in sync, and the menu only closes when the pointer leaves the whole area, the user clicks outside, presses Escape, or picks an action. The search box is roughly twice as wide and aligned with the Actions button in a compact flex row that adapts to narrow windows.

## 0.2.4 — 2026-11-21

- Moves mod card covers from built-in desktop UI assets to optional Cloudflare R2 image hosting served through the catalog Worker ([ADR-016](docs/en/architecture/ADR-016-r2-mod-covers.md)), trimming ~5.8 MB from the desktop installer and allowing catalog cover updates without reinstalling the app.
- Includes **Spike Ring (`v0.1.0`)**, runtime performance optimizations for **Bubble Blitz (`v0.1.2`)**, **Roller Carnival (`v0.1.8`)**, **Standalone HD (`v0.1.2`)**, and **Player Spotlight (`v0.1.1`)** in the live catalog.

## 0.2.3 — 2026-11-20

- Adds **Bubble Blitz (`v0.1.0`)**, a new first-party 3D hybrid industrial bomb arena minigame with 3 HP, a 4-second downed state (bump rivals to finish, or auto-revive with the syringe), 4 randomized maps including industrial conveyors, vanilla explosion/prop assets, and a local CRT status bar.
- Introduces the **Multi-Minigame Coexistence Hub** ([ADR-015](docs/en/architecture/ADR-015-multi-minigame-hub.md)) and updates **Roller Carnival** to `v0.1.6` so multiple first-party minigames can stay installed together across Default, Custom Playlist, Arcade, Local, and CRT Picker pools.

## 0.2.2 — 2026-11-20

- Built-in mod loader v5 tracks deferred startup HUD layers (such as MachineParty+ voice controls) so overlapping lobby mod buttons separate reliably without moving vanilla buttons.
- Settings now shows the built-in loader version and adds a Reload loader button. After an app update, the manager automatically upgrades an outdated built-in loader once the game is closed.

## 0.2.1 — 2026-11-20

- Built-in mod loader v4 automatically separates overlapping mod buttons in the lobby (such as MachineParty+ and Lobby Bots) without modifying mods or moving vanilla game buttons.

## 0.2.0 — 2026-11-20

- Windows x64 stable release for Machine Party v2.1.2. Install and update the eight catalogued mods, or use Settings to restore the Steam original.
- Machine Party is available on Windows. macOS support is planned for a future release.

## 0.1.2-13 — 2026-11-20

- Restore the original game from Settings. The manager waits for Steam verification, checks the game fingerprint, and removes managed mods. Interrupted cleanup can resume on the next scan.

## 0.1.2-12 — 2026-11-20

- The manager asks before closing the selected running game for mod installation, updates or removal. App update prompts wait until the current dialog closes.
- Roller Carnival v0.1.4 refreshes the arena and countdown. Player Spotlight v0.1.0 adds a local overhead light that toggles with F8. Lobby Bots v0.2.2 supports Disco Dodge.

## 0.1.2-11 — 2026-11-19

- Install Standalone HD and compatible new first-party mods from the signed catalog.
- In Installed, check for mod updates, review the target version and game copy, and confirm before downloading. The Windows installer supports English, Simplified Chinese and Traditional Chinese.

## 0.1.2-10 — 2026-11-19

- Open **Installed** and select **Update to** on a managed mod. The manager verifies the new package and restores the old version if replacement fails before commit. Other installed mods keep their versions.
- Roller Carnival v0.1.2 adds an overhead view and player drop-in at the start of a round. Lobby Bots v0.1.5 aligns the host controls in the upper-right corner.

## 0.1.2-9 — 2026-11-19

- Older Roller Carnival records appear as one installed mod. Uninstall verifies the files recorded for that game copy and preserves other mods from the same repository.
- MPML mods can be uninstalled after an online version or package change. The confirmation shows the installed version. If a clean game reinstall leaves an MPML record marked **Repair needed**, open its details and choose **Uninstall** to clear the record.

## 0.1.2-8 — 2026-11-19

Windows preview 0.1.2-8 verifies the restored PCK before removing the last managed mod, preserves shared loaders for linked mods, and checks that the game is closed immediately before replacing its PCK.

## 0.1.2-7 — 2026-11-19

Windows preview with six online mods, verified source-to-MPML conversion, and confirmation of the mods removed during switching.

## 0.1.2-6 — 2026-11-19

Removed special `firstParty` UI badges and catalog overrides so every mod packaged into R2 (`roller-carnival v0.1.0` included) follows the exact same catalog schema, R2 Worker download flow, and UI presentation.

## 0.1.2-5 — 2026-11-19

Windows preview `0.1.2-5` enables `v2.1.2` test installation across all five catalogued mods (`Overtime v1.7`, `MachineParty+ v2.1.0`, `Broadcast 8P Freecam v0.91`, `Binary1936 eight-player mod v1.5`, and `Roller Carnival v0.1.0`), adding `loader-files`, PowerShell, and bundled-Python support, mutual-exclusion conflict checks, and the manager's clean-room PCK auto-loader (`pck_loader.rs` + `mpm_bootstrap.gd`) with lossless vanilla restoration.

### Added

- Deterministically package mods under `mods/<id>/` (`roller-carnival v0.1.0`) via `scripts/pack-mod.mjs` into R2 + `services/catalog-worker`, downloading and verifying via SHA-256 identically to all other catalog entries.

## 0.1.2-4 — 2026-11-19

The Windows preview tests unified installation and uninstallation outcome headings, one automatic retry for catalog timeouts or transient network failures, and explicitly unsigned preview installers when no code-signing identity is configured.

### Changed

- Uninstall now runs a structured step-by-step dialog with read-back verification and retry; rescanning keeps an existing valid game folder if detection finds zero or multiple copies.
- Settings use a three-button segmented language switcher, right-aligned game folder controls showing only the root path and version tag (removing the redundant full-recheck button), and a unified manager row linking to GitHub on the left with the version number and update indicator dot on the right.
- Replaced the top update banner button with a non-forcing update dialog that opens automatically once per release (queuing behind active dialogs) and displays release notes when available.

## 0.1.2-3 — 2026-11-19

Closing a download cancels the transfer and frees the install button. Packages can be served from the existing mirror’s edge cache. The list uses remote entries and offers a retry on sync failure. Offline copies of the last successful catalog are labeled.

## 0.1.2-2 — 2026-11-19

The Windows preview supports Overtime v1.7 on the pinned v2.1.2 game build. Choose Install once. If the game folder is missing, select a copy before the download starts. The dialog downloads the package if needed, verifies it and installs it. Cached packages can be installed offline. Close the game before modifying a copy. Other catalog entries list compatibility as unconfirmed until a supported build is documented.

## 0.1.2-1 — 2026-11-19

Windows x64 preview for testing the refreshed interface, online mod catalog, game folder detection and per-copy status. This preview enables installation and offline restoration of the bundled Overtime v1.7 profile on Windows for testing.

### Changed

- Reorganised the repository into `apps/desktop`, `services/update-worker` and `catalog`. The mod list now comes from a single `catalog/mods.json`. No visible change for players.
- Documentation is available in English, Simplified Chinese and Traditional Chinese, with architecture decision records.

### Added

- Contributor guide, security and support policies, issue and pull request templates, and source checks on every push.

## 0.1.1 — 2026-11-18

### Added

- Apple Silicon Mac build with signed in-app updates sharing the Windows stable channel.

## 0.1.0 — 2026-11-18

### Added

- First prototype: bundled catalog of four candidate mods with search, details and author links in three languages.
- Steam game detection, manual folder selection and per-copy version comparison.
- Signed in-app updates for Windows x64, served through the project's update Worker.
