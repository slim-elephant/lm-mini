#include "flutter_window.h"

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <cwctype>
#include <optional>

#include <iphlpapi.h>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/standard_method_codec.h>
#include "resource.h"
#include "utils.h"

namespace {

constexpr UINT kTrayIconId = 1;
constexpr UINT kTrayCallback = WM_USER + 1;
constexpr DWORD kLlamaSidecarPort = 8741;

DWORD TcpPortToHost(DWORD networkPort) {
  return ((networkPort & 0xFF) << 8) | ((networkPort >> 8) & 0xFF);
}

void TerminateProcessListeningOnPort(DWORD port) {
  DWORD size = 0;
  if (GetExtendedTcpTable(nullptr, &size, FALSE, AF_INET,
                           TCP_TABLE_OWNER_PID_LISTENER, 0) !=
      ERROR_INSUFFICIENT_BUFFER) {
    return;
  }
  auto* table = static_cast<MIB_TCPTABLE_OWNER_PID*>(malloc(size));
  if (table == nullptr) {
    return;
  }
  if (GetExtendedTcpTable(table, &size, FALSE, AF_INET,
                           TCP_TABLE_OWNER_PID_LISTENER, 0) == NO_ERROR) {
    for (DWORD i = 0; i < table->dwNumEntries; i++) {
      if (TcpPortToHost(table->table[i].dwLocalPort) != port) {
        continue;
      }
      const DWORD pid = table->table[i].dwOwningPid;
      if (pid <= 4) {
        continue;
      }
      HANDLE handle = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
      if (handle != nullptr) {
        TerminateProcess(handle, 1);
        CloseHandle(handle);
      }
    }
  }
  free(table);
}

bool CanQueryProcess(DWORD pid) {
  HANDLE handle =
      OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (handle == nullptr) {
    return false;
  }
  CloseHandle(handle);
  return true;
}

bool IsLlamaServerPid(DWORD pid) {
  HANDLE handle =
      OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (handle == nullptr) {
    return false;
  }
  wchar_t path[MAX_PATH];
  DWORD size = MAX_PATH;
  const BOOL ok = QueryFullProcessImageNameW(handle, 0, path, &size);
  CloseHandle(handle);
  if (!ok) {
    return false;
  }
  std::wstring lower(path);
  std::transform(lower.begin(), lower.end(), lower.begin(), ::towlower);
  return lower.find(L"llama-server") != std::wstring::npos;
}

int MapInt(const flutter::EncodableMap& args, const char* key, int fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<int32_t>(&it->second)) {
    return *value;
  }
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

bool MapBool(const flutter::EncodableMap& args, const char* key, bool fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<bool>(&it->second)) {
    return *value;
  }
  return fallback;
}

std::string MapString(const flutter::EncodableMap& args, const char* key,
                      const char* fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<std::string>(&it->second)) {
    return *value;
  }
  return fallback;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {
  RemoveTray();
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterTrayChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  TerminateLlamaSidecar();
  RemoveTray();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::RegisterTrayChannel() {
  tray_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "lm_mini/desktop_tray",
          &flutter::StandardMethodCodec::GetInstance());
  tray_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleTrayCall(call, std::move(result));
      });
}

void FlutterWindow::HandleTrayCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();
  if (method == "ensureTray") {
    EnsureTray();
    result->Success();
    return;
  }
  if (method == "setStatus") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    std::wstring tip = L"LM Mini Home";
    if (args != nullptr) {
      tip = Utf16FromUtf8(MapString(*args, "tooltip", "LM Mini Home"));
    }
    EnsureTray();
    UpdateTrayTip(tip);
    result->Success();
    return;
  }
  if (method == "setKeepAlive") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    keep_alive_ = args != nullptr && MapBool(*args, "enabled", false);
    SetQuitOnClose(!keep_alive_);
    if (keep_alive_) {
      EnsureTray();
    }
    result->Success();
    return;
  }
  if (method == "showMainWindow") {
    ShowMainWindow();
    result->Success();
    return;
  }
  if (method == "terminate") {
    QuitApp();
    result->Success();
    return;
  }
  if (method == "setSidecarPid") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    sidecar_pid_ = args != nullptr
                        ? static_cast<DWORD>(MapInt(*args, "pid", 0))
                        : 0;
    result->Success();
    return;
  }
  result->NotImplemented();
}

void FlutterWindow::EnsureTray() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }
  if (!tray_added_) {
    tray_icon_ = {};
    tray_icon_.cbSize = sizeof(NOTIFYICONDATA);
    tray_icon_.hWnd = hwnd;
    tray_icon_.uID = kTrayIconId;
    tray_icon_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    tray_icon_.uCallbackMessage = kTrayCallback;
    tray_icon_.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
    wcsncpy_s(tray_icon_.szTip, L"LM Mini Home", _TRUNCATE);
    if (Shell_NotifyIcon(NIM_ADD, &tray_icon_)) {
      tray_added_ = true;
    }
    return;
  }
  tray_icon_.hWnd = hwnd;
  Shell_NotifyIcon(NIM_MODIFY, &tray_icon_);
}

void FlutterWindow::RemoveTray() {
  if (!tray_added_) {
    return;
  }
  Shell_NotifyIcon(NIM_DELETE, &tray_icon_);
  tray_added_ = false;
}

void FlutterWindow::UpdateTrayTip(const std::wstring& tooltip) {
  if (!tray_added_) {
    return;
  }
  wcsncpy_s(tray_icon_.szTip, tooltip.c_str(), _TRUNCATE);
  Shell_NotifyIcon(NIM_MODIFY, &tray_icon_);
}

void FlutterWindow::ShowTrayMenu() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }
  POINT pt;
  GetCursorPos(&pt);
  HMENU menu = CreatePopupMenu();
  AppendMenu(menu, MF_STRING, IDM_TRAY_SHOW, L"Show LM Mini Home");
  AppendMenu(menu, MF_STRING, IDM_TRAY_HOST, L"Share with Phone...");
  AppendMenu(menu, MF_STRING, IDM_TRAY_SETTINGS, L"Settings...");
  AppendMenu(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenu(menu, MF_STRING, IDM_TRAY_QUIT, L"Quit LM Mini Home");
  SetForegroundWindow(hwnd);
  TrackPopupMenu(menu, TPM_RIGHTBUTTON | TPM_BOTTOMALIGN | TPM_LEFTALIGN, pt.x,
                 pt.y, 0, hwnd, nullptr);
  DestroyMenu(menu);
}

void FlutterWindow::ShowMainWindow() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }
  if (IsIconic(hwnd)) {
    ShowWindow(hwnd, SW_RESTORE);
  } else {
    ShowWindow(hwnd, SW_SHOW);
  }
  SetForegroundWindow(hwnd);
}

void FlutterWindow::QuitApp() {
  keep_alive_ = false;
  SetQuitOnClose(true);
  TerminateLlamaSidecar();
  RemoveTray();
  HWND hwnd = GetHandle();
  if (hwnd != nullptr) {
    DestroyWindow(hwnd);
  } else {
    PostQuitMessage(0);
  }
}

void FlutterWindow::TerminateLlamaSidecar() {
  if (sidecar_pid_ > 4) {
    if (IsLlamaServerPid(sidecar_pid_) || !CanQueryProcess(sidecar_pid_)) {
      HANDLE handle = OpenProcess(PROCESS_TERMINATE, FALSE, sidecar_pid_);
      if (handle != nullptr) {
        TerminateProcess(handle, 1);
        CloseHandle(handle);
      }
    }
  }
  sidecar_pid_ = 0;
  TerminateProcessListeningOnPort(kLlamaSidecarPort);
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_CLOSE && keep_alive_) {
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }

  if (message == kTrayCallback) {
    if (LOWORD(lparam) == WM_RBUTTONUP || LOWORD(lparam) == WM_CONTEXTMENU) {
      ShowTrayMenu();
      return 0;
    }
    if (LOWORD(lparam) == WM_LBUTTONDBLCLK || LOWORD(lparam) == WM_LBUTTONUP) {
      ShowMainWindow();
      return 0;
    }
  }

  if (message == WM_COMMAND) {
    switch (LOWORD(wparam)) {
      case IDM_TRAY_SHOW:
        ShowMainWindow();
        return 0;
      case IDM_TRAY_HOST:
        ShowMainWindow();
        if (tray_channel_) {
          tray_channel_->InvokeMethod("openHost", nullptr);
        }
        return 0;
      case IDM_TRAY_SETTINGS:
        ShowMainWindow();
        if (tray_channel_) {
          tray_channel_->InvokeMethod("openSettings", nullptr);
        }
        return 0;
      case IDM_TRAY_QUIT:
        QuitApp();
        return 0;
      default:
        break;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
