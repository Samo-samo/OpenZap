# Changelog

## v0.6.1 — 2026-09-23

Polish on top of the custom remote layouts: more keys to build with, a screen-awake option for the remote, and smarter editor snapping.

### Added

- Eight more palette keys in a new Apps & inputs group: YouTube, Netflix, fast access, source list, web browser, network type, hybrid broadcast and current program.
- Keep-screen-awake option for the remote screen with timeout choices (Off, 30 seconds, 1/5/10/15 minutes, Always; defaults to 5 minutes). The lock is released when you leave the remote or the timeout elapses.
- App version row at the bottom of Settings (OpenZap version + build).
- Editor snapping improvements: tiles dragged between two neighbours snap so both gaps match, and tiles snap back to their drag-start position (shown as a ghost outline).

### Changed

- Layout-editor zoom is now behind a kill-switch in Settings and off by default; a zoomed canvas snaps back to 1x while it is off.

### Fixed

- Disabling editor zoom while zoomed no longer leaves the canvas zoomed; the zoom-reset button only shows when zoom is enabled.

### Known issues

- Canvas zoom-out can still leave the viewport stranded showing half-cut buttons at content edges (zoom is now off by default, so fewer users hit this) — workaround: the zoom reset button in the editor toolbar.
- Live status tracking still non-functional on MB180 (7681 silent; default off, marked "in development").

## v0.6.0 — 2026-09-19

Custom remote layouts: build your own button arrangements on a free-form canvas, on top of the classic / compact / minimal presets.

### Added

- Multiple named custom layouts: create new layouts, switch between presets and saved layouts from the remote screen's three-dot menu, and manage them (rename, delete, export/import via clipboard) from the manage dialog.
- Layout editor: drag tiles with alignment guides and canvas-edge snap, resize with the corner handle on desktop or pinch on touch, aspect-ratio lock, snap toggle, undo/redo, canvas zoom (Ctrl+wheel on desktop, pinch on empty area on touch), and reset-to-template.
- Adaptive preset menus: the layout menu adapts its density to the available space.
- Turkish and English strings for all new layout UI, kept in sync.

### Changed

- Layout selection moved out of Settings into the remote screen's three-dot menu (presets, saved layouts, new-layout and manage entries); Apps and key test are reached from the same menu.
- The remote screen allows wider content so custom canvases have room.

### Fixed

- Canvas zoom keeps the viewport on the content instead of stranding it on empty space.
- Touch drag uses pointer tracking with scroll lock so tiles follow the finger; tile drag moves go through the pan recognizer for pointer capture.
- Resize badge and toolbar behavior polished on desktop.

## v0.5.0

Prior release: Android & device/app UX (release builds, discovery fallback, context menu on the device list, apps screen with virtual-remote shortcuts, key test screen, preset remote layouts, quick controls, Material You).

## v0.4.0

Prior release: user experience foundations (device management, sleep timer, settings, TR/EN localization, themes, first release builds).
