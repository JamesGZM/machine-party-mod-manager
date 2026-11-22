# UI design specification

**English** · [简体中文](../zh-CN/ui-design.md) · [繁體中文](../zh-TW/ui-design.md)

This describes the current desktop UI and marks what is not implemented yet. See the [current screenshot](../images/screenshot-catalog.png). Redesigns update this page directly instead of appending superseding sections.

## Visual style: Machine Party

Taken from the game's wine-red overalls and brass machinery: deep wine backgrounds, brass accents and cream text. Rounded corners and raised buttons add some game character without competing with mod covers, which stay the visual focus.

- **Brand**: the gear badge mark, a cream masked face inside a brass gear on a rounded wine plate. The UI uses `apps/desktop/ui/images/logo.svg`; the app icon source is `apps/desktop/artwork/app-icon.svg` (with macOS padding). Run `npx --yes --package @tauri-apps/cli@2.12.5 tauri icon ../artwork/app-icon.svg -o /tmp/icons` in `apps/desktop/src-tauri` and copy only the desktop sizes into `icons/`.
- **Design tokens**: colours, fonts, type scale, spacing, radii, shadows and motion are all defined in `apps/desktop/ui/tokens.css`. Components and layout reference variables only and add no new colour values.
  - Backgrounds from dark to light: sidebar `--wine-900`, main area `--wine-850`, cards `--wine-800`, hover `--wine-750`; the selected navigation item uses `--wine-600`.
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

- **Sidebar**: the mark with `MACHINE PARTY` and the "Mod Manager" subtitle at the top. Primary navigation "Mod catalog" and "Installed", each with an icon and at least 44px high; the selected item has a wine fill and a brass icon. "Settings" at the bottom shows a small red `.update-dot` when a newer manager release is available.
- **Header**: a condensed page title and subtitle on the left; on the catalog page an "Actions" menu sits immediately left of the pill search box ("Search mod titles") in a compact, right-aligned flex row. The search box is roughly twice its earlier width, shares the button's 36px height, shrinks on medium windows and wraps below the button on narrow ones. Hovering or clicking opens Install selected / Update selected / Uninstall selected, each with a live count of ticked cards matching that action. The refresh button beside the catalog title spins while the list reloads.
- **Content**: an equal-height card grid that fills the available width, with a minimum card width of about 280px. Settings is a vertical list of panels up to 720px wide.
- **Narrow windows (≤760px)**: the sidebar collapses to the mark and icons, the header stacks vertically and the tools wrap; search flexes into the remaining width without overlapping the Actions button.

## Mod card

1. The 16:9 cover groups the catalog version and category at the top right. The catalog supplies the category. The interface translates Expansion, Game, Tool and Graphics. An absent or unknown category leaves the version on its own. The cover shows a skeleton while loading and falls back to the title on a wine gradient.
2. The title opens details. The summary and supported game version appear below. Managed installations also show the local and catalog versions.
3. The catalog offers an update when the installed version is eligible. Installed uses the uninstall action for that same mod. Scan or repair issues lead to the existing recovery actions.

## Batch operations

The catalog's "Actions" menu offers Install selected, Update selected and Uninstall selected. Every catalog card has a persistent checkbox at the top-left of its cover; the tick state is stored by mod id, so searching, sorting, filtering and page switches never lose it. A brass-tinted strip above the grid shows the ticked count and offers Select visible and Clear. The menu badge for each action is the intersection of the ticked cards with that action's condition (not installed / installed with an approved newer release / manager-installed), recomputed live. Ticking a card never changes the visuals of unticked cards; only a ticked card gets a brass outline.

Clicking a menu entry acts only on the current ticked cards. An empty selection shows "Select the mods you want to act on first." instead of running anything; ticked cards that no longer match the action are filtered out and reported. A confirmation dialog lists the exact mods to be processed - uninstall uses a deliberately stronger wording - and only then does execution start. The button and dropdown are one interaction area: a transparent bridge covers the gap, hover and click stay in sync, and the menu closes only when the pointer leaves the whole area, the user clicks outside, presses Escape, or picks an action.

Execution opens a modal progress dialog ("Installing mods…" / "Updating mods…" / "Uninstalling mods…") listing every target with a per-item status and a total progress bar. The driver reuses the single-mod commands serially, rechecks eligibility and the game's closed state before each write, rescans after failures, and never stops the queue on one failure. Navigation, search, refresh, single-card buttons, checkboxes and dialog closing are locked while running. When finished, a summary reports succeeded / failed / skipped counts; successful mods are unticked while failed and skipped ones stay selected for retry.

## Details dialog

In order: the detailed description (multiplayer conditions, required loader, conflicts), supported game version, catalog version, local version and state note when present, optional cache-clear action, package download link (when mirror-approved), and the author page link with an external-link icon.

## Settings

Settings consists of three panels:

- **Language**: a three-button `.segmented` control (`简体中文` · `繁體中文` · `English`). The system language is used on first launch and the user's choice is saved in `localStorage`.
- **Game folder**: displays the `Game folder` heading alongside a compact `v2.1.2` version tag when validated and the saved game root path in a monospaced font (hiding inner subdirectories such as `Machine Party_Windows`), with "Select game folder" and "Scan again" buttons aligned on the right. Rescanning preserves an existing valid selection if detection finds zero or multiple copies. No manual full-recheck button is shown.
- **Manager & updates**: a single merged row with the underlined `Machine Party Mod Manager` link on the left (opening the GitHub repository via `open_project`) and the current version button on the right with automatic silent startup update checks and a red `.update-dot` when a newer version is available. There is no top update banner button; instead, a non-forcing update dialog opens automatically once per release (queuing behind any currently open dialog, dismissible with "Later" stored in `localStorage`, and manually reopenable from the version button), displaying release `notes` when present or a default prompt, with "Update and restart" and download progress as a bar and percentage.

## First launch

A single game copy loads directly; several copies open a dialog listing candidate paths; none prompts to choose a folder or browse first, with "Set up later".

## Planned

- A game status line at the bottom of the sidebar: a green dot with "Game version v2.1.2", switching to a warning colour that opens folder selection when no game is detected.
- A one-click "Switch" button for mods that conflict with the active one: names the mod being replaced and prepares the new package before restoring the old mod and applying the new one.
