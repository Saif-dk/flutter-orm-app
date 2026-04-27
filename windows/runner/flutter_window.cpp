#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
// method channel for native audio
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>
#include <mmsystem.h>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Register a simple method channel to play/stop launch audio.
  // The channel persists in a static unique_ptr so the handler remains alive.
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> audio_channel;
  audio_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "orm_risk_assessment/launch_audio",
      &flutter::StandardMethodCodec::GetInstance());

  audio_channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string method = call.method_name();
        if (method == "play") {
          // Determine path to the packaged flutter assets.
          wchar_t module_path[MAX_PATH];
          ::GetModuleFileNameW(NULL, module_path, MAX_PATH);
          std::wstring path_w(module_path);
          size_t pos = path_w.find_last_of(L"\\/");
          std::wstring dir = (pos == std::wstring::npos) ? path_w : path_w.substr(0, pos);
          // Flutter assets are packaged under <exe-dir>\data\flutter_assets\assets\...
          std::wstring asset_path = dir + L"\\data\\flutter_assets\\assets\\sounds\\helicopter.mp3";

          // Use MCI to open and play the file.
          std::wstring open_cmd = L"open \"" + asset_path + L"\" type mpegvideo alias helicopteraudio";
          mciSendStringW(open_cmd.c_str(), NULL, 0, NULL);
          mciSendStringW(L"play helicopteraudio", NULL, 0, NULL);
          result->Success();
        } else if (method == "dispose") {
          mciSendStringW(L"stop helicopteraudio", NULL, 0, NULL);
          mciSendStringW(L"close helicopteraudio", NULL, 0, NULL);
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
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
