# UI design specification

**English** · [简体中文](../zh-CN/ui-design.md) · [繁體中文](../zh-TW/ui-design.md)

This describes the current desktop UI and marks what is not implemented yet. See the [current screenshot](../images/screenshot-catalog.png). Redesigns update this page directly instead of appending superseding sections.

## Visual style: Machine Party

Taken from the game's wine-red overalls and brass machinery: deep wine backgrounds, brass accents and cream text. Rounded corners and raised buttons add some game character without competing with mod covers, which stay the visual focus.

- **Brand**: the gear badge mark, a cream masked face inside a brass gear on a rounded wine plate. The UI uses `apps/desktop/ui/images/logo.svg`; the app icon source is `apps/desktop/artwork/app-icon.svg` (with macOS padding). Run `npx --yes --package @tauri-apps/cli@2.12.5 tauri icon ../artwork/app-icon.svg -o /tmp/icons` in `apps/desktop/src-tauri` and copy only the desktop sizes into `icons/`.
- **Design tokens**: colours, fonts, type scale, spacing, radii, shadows and motion are all defined in `apps/desktop/ui/tokens.css`. Components and layout reference variables only and add no new colour values.
  - Backgrounds from dark to light: top bar `--wine-900`, main area `--wine-850`, cards `--wine-800`, hover `--wine-750`; active controls use `--wine-600`.
  - The accent is brass `--brass-500`, used for primary buttons and links; success is a pale green and warnings a warm orange.
  - Titles and the brand use a condensed bold face (Avenir Next Condensed / Bahnschrift Condensed), body text uses system UI fonts and version numbers use a monospaced font.
- **Shared components** (`components.css`, created by `dom.js` and `icons.js`):
  - Button `button(text, action, variant, icon)`: `primary` raised brass, `secondary` outlined, `ghost` without fill and `link` text link; card buttons add `btn-block` to fill the width.
  - Tag `tag(text, tone)`: a dark pill with `accent`, `success` and `warning` tones; version tags use the monospaced font.
  - Card `.card`, panel `.panel`, text field `.field`, segmented control `.segmented` / `.segment`, dialog `.dialog` (with `.release-notes` for update notes), indicator dot `.update-dot`, progress bar `progress()` and skeleton `.skeleton`.
  - Buttons in a dialog are collected into its action row; text links stay in the body.
  - Icons are 24px line icons that follow the text colour, created by `icon(name)`; they replace the earlier character icons.
- **Motion**: cards rise and fade in one after another when a page opens (not while searching); on hover they lift with a brass outline and a slight cover zoom. Buttons press down 1px, dialogs scale in with a spring, covers shimmer as skeletons until loaded and the brand mark tilts on hover. All durations drop to zero when the system requests reduced motion.
- Every focusable element has a visible brass focus ring and works with the keyboard.

## Layout

- **Top bar**: sticky translucent bar spanning the window with the `MACHINE PARTY` mark and "Mod Manager" subtitle on the left, and the pill search box ("Search mod titles"), refresh icon button (spins while reloading), and settings gear button on the right. The settings button displays a small red `.update-dot` when a newer manager release is available.
- **Content**: a full-width centered container (`max-width: 1440px`) holding the catalog toolbar and an equal-height card grid with a minimum card width of about 280px. There is no separate sidebar or "Installed" page; status filtering handles Enabled, Disabled, Not installed and Updates in place (and also lists any unlisted installed records under All / Enabled / Disabled). Library entries (`role: "library"`, such as `mpm-core`) stay hidden from browse cards and are resolved automatically via `requires`.
- **Narrow windows (≤680px)**: the top bar wraps onto two rows so search expands across the full width cleanly.

## Mod card

1. The 16:9 cover groups the catalog version and category at the top right, and displays a `Disabled` tag before them when a loader mod is disabled. The catalog supplies the category. The interface translates Expansion, Game, Tool and Graphics. An absent or unknown category leaves the version on its own. The cover shows a skeleton while loading and falls back to the title on a wine gradient.
2. The title opens details (listing prerequisites, current enable/disable state, and one-click conflict **Switch** when conflicting mods are installed). The summary and supported game version appear below. Managed installations also show the local and catalog versions.
3. Card actions show the primary action (**Install**, **Update to …**, **Switch**, or **Uninstall**) alongside a per-mod **Enable / Disable** switch (`.mod-switch`) for managed loader mods. When an installed mod has an eligible update, its card also shows a compact uninstall icon button beside the action row. Scan or repair issues lead to the existing recovery actions.

## Catalog toolbar, filters and batch mode

Above the catalog grid sits a compact toolbar combining filters on the left and a **Batch** mode toggle on the right (keeping the top bar focused on brand, search, refresh and settings).

- **Filters**: lightweight underline status tabs (`All` · `Enabled` · `Disabled` · `Not installed` · `Updates`) displaying live counts scoped dynamically to the active category and search query (with a brass accent pill when updates are available), separated by a subtle divider from dynamic category tags (`All types`, `Expansion`, `Game`, `Tool`, `Graphics`). Filtering composes with the search query and offers a "Reset filters" action when nothing matches.
- **Batch mode**: cards stay clean during normal browsing. Clicking **Batch** enters batch mode: each card displays a top-left checkbox (clicking the card body also toggles selection while individual card buttons pause), and an inline action strip expands inside the toolbar with the selected count, **Select visible / Deselect visible**, **Clear**, and direct **Install** (covering both fresh installs and approved updates), **Enable**, **Disable**, and **Uninstall** buttons showing live counts of ticked, matching mods.
- **Execution**: clicking an action confirms the exact queue (including automatically resolved prerequisites or dependent-mod checks, and reporting any ticked cards skipped as ineligible) and runs the existing single-mod commands serially inside a modal progress dialog, rechecking eligibility and the game-closed state before every write, rescanning after failures, and reporting succeeded / failed / skipped counts. Successful mods are unticked while failed and skipped ones remain selected for retry.

## Details dialog

In order: the detailed description (multiplayer conditions, required loader, conflicts), supported game version, catalog version, local version and state note when present, optional cache-clear action, package download link (when mirror-approved), and the author page link with an external-link icon.

## Settings modal

Opened via the top-right gear button in an independent `<dialog>` (`#settings-dialog`) so it never collides with install, update or restore dialogs. Inside are panels for:

- **Language**: a three-button `.segmented` control (`简体中文` · `繁體中文` · `English`). The system language is used on first launch and the user's choice is saved in `localStorage`.
- **Game folder**: displays the `Game folder` heading alongside a compact `v2.1.2` version tag when validated and the saved game root path in a monospaced font (hiding inner subdirectories such as `Machine Party_Windows`), with "Select game folder" and "Scan again" buttons aligned on the right. Rescanning preserves an existing valid selection if detection finds zero or multiple copies. No manual full-recheck button is shown.
- **Built-in loader**: shows the current managed loader version tag (for example `v6`, or `vFrom → vTarget` when an upgrade is pending), preserves external `MachinePartyModLoader.exe` installations untouched, upgrades outdated managed loaders automatically while the game is closed (or prompts to close a running game), and provides **Reload loader**.
- **Restore the Steam original**: launches Steam integrity verification (**Start restore**) with a progress dialog, waiting/stop-waiting controls, and post-verification cleanup of managed mods while leaving manual mods intact.
- **Manager & updates**: a single merged row with the underlined `Machine Party Mod Manager` link on the left (opening the GitHub repository via `open_project`) and the current version button on the right with automatic silent startup update checks and a red `.update-dot` when a newer version is available. There is no top update banner button; instead, a non-forcing update dialog opens automatically once per release (queuing behind any currently open dialog, dismissible with "Later" stored in `localStorage`, and manually reopenable from the version button), displaying release `notes` when present or a default prompt, with "Update and restart" and download progress as a bar and percentage.

## First launch

A single game copy loads directly; several copies open a dialog listing candidate paths; none prompts to choose a folder or browse first, with "Set up later".

## Planned

- macOS desktop support and game-copy detection once *Machine Party* releases a macOS version.
