#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/method_result.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <string>

#include <shellapi.h>

#include "win32_window.h"

// A window that hosts a Flutter view plus the Home system-tray icon.
class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void RegisterTrayChannel();
  void HandleTrayCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void EnsureTray();
  void RemoveTray();
  void UpdateTrayTip(const std::wstring& tooltip);
  void ShowTrayMenu();
  void ShowMainWindow();
  void QuitApp();
  void TerminateLlamaSidecar();

  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> tray_channel_;
  NOTIFYICONDATA tray_icon_{};
  bool tray_added_ = false;
  bool keep_alive_ = false;
  DWORD sidecar_pid_ = 0;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
