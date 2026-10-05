import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var mlxBridge: MLXBridge?
  private var speechBridge: MacSpeechBridge?

  /// Matches Flutter desktop shell `Color(0xFF0E1117)`.
  private static let shellBackground = NSColor(
    calibratedRed: 14.0 / 255.0,
    green: 17.0 / 255.0,
    blue: 23.0 / 255.0,
    alpha: 1.0
  )

  /// Roomier first-launch default so home + chat panes aren't cramped.
  private static let defaultContentSize = NSSize(width: 1280, height: 860)
  private static let minimumContentSize = NSSize(width: 900, height: 640)
  private static let defaultSizeAppliedKey = "LMMiniDefaultWindowSize_v1280"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = Self.shellBackground

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.minSize = Self.minimumContentSize
    let needsDefaultSize =
      !UserDefaults.standard.bool(forKey: Self.defaultSizeAppliedKey)
      || windowFrame.width < Self.minimumContentSize.width
      || windowFrame.height < Self.minimumContentSize.height
    if needsDefaultSize {
      applyDefaultWindowSize()
      UserDefaults.standard.set(true, forKey: Self.defaultSizeAppliedKey)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    mlxBridge = MLXBridge(messenger: flutterViewController.engine.binaryMessenger)
    speechBridge = MacSpeechBridge(
      messenger: flutterViewController.engine.binaryMessenger)

    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
      appDelegate.registerPrivacyChannel(with: flutterViewController)
      appDelegate.registerTrayChannel(with: flutterViewController)
    }

    isReleasedWhenClosed = false

    super.awakeFromNib()
    applySeamlessTitleBar()
  }

  /// Menu bar present: hide the window and Dock tile instead of quitting.
  /// Use Quit LM Mini from the status menu (or ⌘Q) to actually exit.
  override func close() {
    if let delegate = NSApp.delegate as? AppDelegate, delegate.shouldHideToTray {
      orderOut(nil)
      delegate.setDockVisible(false)
      return
    }
    super.close()
  }

  private func applyDefaultWindowSize() {
    let target = Self.defaultContentSize
    if let screen = NSScreen.main {
      let visible = screen.visibleFrame
      let width = min(target.width, visible.width * 0.92)
      let height = min(target.height, visible.height * 0.90)
      let origin = NSPoint(
        x: visible.midX - width / 2,
        y: visible.midY - height / 2
      )
      setFrame(NSRect(origin: origin, size: NSSize(width: width, height: height)), display: true)
    } else {
      setContentSize(target)
    }
  }

  /// Transparent native chrome; Flutter draws the custom title bar.
  private func applySeamlessTitleBar() {
    title = ""
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    styleMask.insert(.fullSizeContentView)
    isMovableByWindowBackground = true
    backgroundColor = Self.shellBackground

    if #available(macOS 11.0, *) {
      titlebarSeparatorStyle = .none
    }

    if let contentView {
      contentView.wantsLayer = true
      contentView.layer?.backgroundColor = Self.shellBackground.cgColor
    }
  }
}
