# Roadmap

The roadmap represents the planned evolution of OpenZap.

Items and priorities may change as the project evolves.

---

## Current status

- Release: v0.4.0 pre-alpha. First release builds available: Windows
  (`build/windows/x64/runner/Release`) and Android (`app-release.apk`, signed
  with the project keystore). No tagged GitHub releases yet.
- Working Windows and Android builds with a minimal Riverpod UI (device
  discovery, remote control, live status, sleep timer, settings, apps screen,
  TR/EN localization) validated against a real VESTEL 50U9510M (MB180).
- 57 tests pass, `flutter analyze` clean, Windows and Android release builds
  succeed.
- Open gaps: live status tracking not working on MB180 (no frames pushed on
  the 7681 channel; default off, marked "in development"), quick launcher
  uses the fixed default apps (YouTube, Netflix, HDMI, portal), Wake-on-LAN
  not started (TV is on Wi-Fi).

---

# v0.1.0 — Foundation

Status: Completed

Goals:

* Repository setup
* Project architecture
* Documentation
* Flutter foundation
* Core infrastructure

Done:

* Clean Architecture skeleton (`app/ core/ features/ integrations/ shared/`)
* `PRD.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `.ai/AI_CONTEXT.md`
* Flutter 3.44 / Dart 3.12 project; Riverpod, ARB localization, lints
* Core networking (`DartHttpProbe`, `DartUdpBroadcastSocket`)

---

# v0.2.0 — Networking

Status: Completed

Goals:

* Device discovery
* Network communication
* Protocol abstraction
* Connection management

Done:

* Discovery abstraction (`DeviceDiscovery`) + `DiscoveryService`
* HTTP probe + UDP broadcast socket in `core/networking`
* Subnet scanning via `route print -4` (default-route subnet, 254 hosts)
* Scan progress per host + cancellable batches

---

# v0.3.0 — Vestel Integration

Status: Completed (7681 verification pending)

Goals:

* Vestel Smart TV protocol
* Remote control
* Device pairing
* Command handling

Supported Brands:

* Vestel Smart TV

Done:

* Confirmed protocol (dd.xml discovery, SmartCenter remote keys, fixed
  Content-Length requirement)
* Remote control (`VestelRemoteControl`) with all mapped keys
* Command handling + feedback modes
* 7681 status/events (`VestelTvStatus`) implemented with parser
* Device pairing covered by last-device persistence + manual device list

In development / not working on MB180:

* Live status tracking: the TV opens the 7681 WebSocket but never pushes
  frames (tested: power on/off, app launch, source change). Tracking is off by
  default and hidden from the UI when disabled.

---

# v0.4.0 — User Experience

Status: Completed (first release builds shipped)

Goals:

* Device management
* Quick launcher
* Wake-on-LAN
* Sleep timer
* Settings
* Localization
* Themes

Done:

* Device management: discovery list, recent device, manual add/remove
* Sleep timer: presets, custom slider, manual minute entry, hours/minutes
  display options
* Settings: command feedback, theme mode, language, sleep-timer display,
  live status toggle, device management
* Localization: full TR/EN ARB set
* Themes: light/dark + system, pointer cursors on desktop
* Snackbar feedback (success green, error red, immediate replace)
* Dismissible same-network warning on the start screen (settings toggle)
* First release builds: Windows (Release folder) + Android (signed APK)

Skipped / not started (research done, see `.ai/vestel-protocol-notes.md`):

* Quick launcher — DIAL app launch is viable: `POST /apps/Netflix`,
  `/apps/YouTube`, SmartCenter + key navigation; HDMI via key 1056.
* Wake-on-LAN — works via UDP magic packet to the TV MAC (broadcast:9),
  retries + poll; do not combine with the POWER key.
* Device reconnect/health checks for saved offline devices

---

# v0.5.0 — Android

Status: Completed (brought forward with v0.4)

Done:

* Android support (manifest: INTERNET/network-state/Wi-Fi permissions,
  cleartext traffic for LAN TV control, app label "OpenZap")
* Discovery fallback via `NetworkInterface` on Android (no `route print`)
* Release signing with a project keystore (`android/key.properties` is
  gitignored)
* Launcher icon generated for Android (adaptive) and Windows

---

# v0.6.0 — Device & App UX

Status: In Progress

Goals:

* Device management polish
* App launcher
* Settings/UX improvements

Done:

* Context menu on the device list (right-click on desktop, long-press on
  touch): save an unsaved device, rename or remove a saved one. Saved devices
  keep their (possibly renamed) name in the list and settings.
* Apps screen (remote screen → Apps): quick-launch YouTube, Netflix, HDMI
  input and the smart portal. On MB180 DIAL is unavailable (403), so launches
  use the virtual-remote shortcut keys (1062/1064/1056/1046).
* Key test screen (Apps → Key test): send a raw key code or one of the known
  shortcut keys to discover and verify codes from the TV room.
* Remote layout (settings): presets classic / compact / minimal plus a custom
  combination — each section (TV status, digits, sleep timer, quick controls)
  can be toggled independently.
* Quick controls on the remote screen (picture format, picture mode, audio
  track, subtitle/audio, subtitles, favorites, settings, teletext — all
  confirmed codes).
* Material You (dynamic color): optional wallpaper-based colors on Android 12+
  via the `dynamic_color` package; the launcher icon gained a monochrome layer
  so Android 13 themed icons match the wallpaper.
* Key test screen now lists every confirmed code in groups (navigation, apps &
  inputs, picture & audio).
* `tool/launch_app.dart` smoke test for app launch.

Skipped / not started (research done, see `.ai/vestel-protocol-notes.md`):

* Custom app list (add/remove/reorder apps in the Apps screen) — defaults are
  fixed for now.
* Customizable key arrangement / drag-to-reorder — presets only for now.
* Wake-on-LAN — deferred: the TV is on Wi-Fi, where magic packets are
  unreliable; revisit if the TV is wired.
* Live status research — deferred; the 7681 channel pushes nothing on MB180.

---

# v0.7.0 — Stabilization

Status: Planned

Goals:

* Performance improvements
* Bug fixes
* Documentation improvements
* Test coverage
* API stabilization

---

# v1.0.0 — First Stable Release

Status: Planned

Goals:

* Stable architecture
* Stable Windows support
* Stable Android support
* Complete Vestel integration
* Production-ready documentation

---

# Future Considerations

The following items are under consideration but are not currently scheduled.

Platforms:

* Linux Desktop
* macOS
* iOS

TV Platforms:

* Samsung Smart TV
* LG Smart TV
* Sony Smart TV
* Android TV
* Google TV

Features:

* Text input
* Touchpad mode
* Advanced app management
* Additional discovery methods
* Automation features
* Developer tools
* Live volume-level display (needs protocol research)