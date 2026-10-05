/// Desktop-only modules (host mode, sidecar runtime, Mac/Windows UI shell).
///
/// Import from desktop entry points and `Platform.isMacOS` gates only.
/// Phone app code should not depend on this library except additive QR parsing.
library;

export 'desktop_platform.dart';
export 'host/desktop_host_service.dart';
export 'host/desktop_host_url.dart';
export 'host/desktop_relay_client.dart';
export 'inference/desktop_sidecar_client.dart';
export 'inference/local_inference_engine.dart';
export 'runtime/desktop_runtime_manager.dart';
export 'tray/desktop_tray_service.dart';
export 'ui/desktop_host_screen.dart';
export 'usb/desktop_usb_bridge.dart';
export 'usb/usbmuxd_client.dart';
