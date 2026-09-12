# Changelog

## v0.6.0 — 2026-09-19

Custom remote layouts: build your own button arrangements on a free-form
canvas, on top of the classic / compact / minimal presets.

### Added

- Multiple named custom layouts: create new layouts, switch between presets
  and saved layouts from the remote screen's three-dot menu, and manage them
  (rename, delete, export/import via clipboard) from the manage dialog.
- Layout editor: drag tiles with alignment guides and canvas-edge snap,
  resize with the corner handle on desktop or pinch on touch, aspect-ratio
  lock, snap toggle, undo/redo, canvas zoom (Ctrl+wheel on desktop, pinch on
  empty area on touch), and reset-to-template.
- Adaptive preset menus: the layout menu adapts its density to the available
  space.
- Turkish and English strings for all new layout UI, kept in sync.

### Changed

- Layout selection moved out of Settings into the remote screen's three-dot
  menu (presets, saved layouts, new-layout and manage entries); Apps and key
  test are reached from the same menu.
- The remote screen allows wider content so custom canvases have room.

### Fixed

- Canvas zoom keeps the viewport on the content instead of stranding it on
  empty space.
- Touch drag uses pointer tracking with scroll lock so tiles follow the
  finger; tile drag moves go through the pan recognizer for pointer capture.
- Resize badge and toolbar behavior polished on desktop.

## v0.5.0

Prior release: Android & device/app UX (release builds, discovery fallback,
context menu on the device list, apps screen with virtual-remote shortcuts,
key test screen, preset remote layouts, quick controls, Material You).

## v0.4.0

Prior release: user experience foundations (device management, sleep timer,
settings, TR/EN localization, themes, first release builds).
