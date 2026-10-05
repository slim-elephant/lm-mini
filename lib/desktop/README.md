# Desktop modules (`lib/desktop/`)

Phone-safe isolation for Mac/Windows host mode and desktop-class inference.

## Mac App Store

| Feature | MAS | Notarized / sandbox-off |
|---------|-----|-------------------------|
| Bundled `llama-server` | Yes | Yes |
| Relay QR host | Yes | Yes |
| A1111 / Comfy / Kokoro proxy | Yes | Yes |
| Menu-bar / tray | Yes | Yes |
| USB (usbmuxd → phone :2348) | **No** (sandbox) | Yes (Mac only) |

USB talks to `/var/run/usbmuxd`. App Store sandbox blocks that socket.

**In-app:** sandboxed builds show that USB is unavailable and link to
[lmmini.com/download.html](https://lmmini.com/download.html) for the full Mac build.
QR **Share with phone** still works on the App Store build.

## Layout

| Path | Role |
|------|------|
| `runtime/` | Bundled `llama-server` |
| `inference/` | `LocalInferenceEngine` |
| `host/` | QR + relay + shared `DesktopRequestProxy` |
| `usb/` | usbmuxd client + `DesktopUsbBridge` |
| `tray/` | Native tray (macOS `NSStatusItem`, Windows notify icon) |
| `ui/` | Share-with-phone screen |

## Deprecating Electron Connect

Mac host lives in this app. Windows Home is the same Flutter app (`flutter build windows`)
with a Vulkan sidecar. `website/connect.html` stays current for Windows/Linux Connect
until a Home zip is published.

## Phone impact

USB **client** remains in `lib/services/usb_bridge_service.dart` (iOS). Desktop host never runs on phone.
