import Flutter
import Foundation
import UIKit
import UniformTypeIdentifiers

/// Picks an MLX model folder (Files, iCloud Drive, another app) and copies it
/// into the app while the folder's security scope is open.
///
/// file_picker only returns the path of a picked folder and never calls
/// startAccessingSecurityScopedResource, so iOS refused every read and MLX
/// import failed for any folder outside LM Mini.
///
/// Methods on `lm_mini/mlx_folder_import`:
///   pick            → {token, name, config} or nil when cancelled.
///                     `config` is config.json's text (nil when missing).
///   copy {token, dest} → total bytes copied into `dest`; ends the scope.
///   release {token} → ends the scope without copying.
final class MlxFolderImport: NSObject, UIDocumentPickerDelegate {
  static let channelName = "lm_mini/mlx_folder_import"

  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private var pendingPick: FlutterResult?
  private var scoped: [String: URL] = [:]

  /// Formats MLX never loads; skipping them saves copying gigabytes.
  private static let skippedExtensions: Set<String> = [
    "gguf", "bin", "pt", "pth", "onnx", "h5", "msgpack", "tflite",
  ]

  init(messenger: FlutterBinaryMessenger, presenter: UIViewController) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    self.presenter = presenter
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "pick":
        self.pick(result)
      case "copy":
        guard let token = args?["token"] as? String,
          let dest = args?["dest"] as? String
        else { return result(FlutterError(code: "bad_args", message: nil, details: nil)) }
        self.copy(token: token, dest: dest, result: result)
      case "release":
        if let token = args?["token"] as? String { self.release(token) }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: Pick

  private func pick(_ result: @escaping FlutterResult) {
    guard pendingPick == nil, let presenter else {
      return result(FlutterError(code: "busy", message: "A folder picker is already open.", details: nil))
    }
    pendingPick = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingPick?(nil)
    pendingPick = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pendingPick else { return }
    pendingPick = nil
    guard let url = urls.first else { return result(nil) }
    guard url.startAccessingSecurityScopedResource() else {
      return result(FlutterError(
        code: "no_access",
        message: "iOS did not allow LM Mini to read that folder. Try moving it to On My iPhone.",
        details: nil))
    }
    let token = UUID().uuidString
    scoped[token] = url
    DispatchQueue.global(qos: .userInitiated).async {
      let config = Self.readText(url.appendingPathComponent("config.json"))
      DispatchQueue.main.async {
        result(["token": token, "name": url.lastPathComponent, "config": config as Any])
      }
    }
  }

  // MARK: Copy

  private func copy(token: String, dest: String, result: @escaping FlutterResult) {
    guard let source = scoped[token] else {
      return result(FlutterError(code: "expired", message: "Pick the folder again.", details: nil))
    }
    DispatchQueue.global(qos: .userInitiated).async {
      var outcome: Any
      do {
        outcome = try Self.copyTree(from: source, to: URL(fileURLWithPath: dest))
      } catch {
        outcome = FlutterError(code: "copy_failed", message: error.localizedDescription, details: nil)
      }
      DispatchQueue.main.async {
        self.release(token)
        result(outcome)
      }
    }
  }

  private func release(_ token: String) {
    scoped.removeValue(forKey: token)?.stopAccessingSecurityScopedResource()
  }

  /// Copies regular, non-hidden files, keeping relative paths. Each read is
  /// coordinated so iCloud Drive downloads files that are not on the phone.
  private static func copyTree(from source: URL, to dest: URL) throws -> Int64 {
    let fm = FileManager.default
    try fm.createDirectory(at: dest, withIntermediateDirectories: true)
    guard let walker = fm.enumerator(
      at: source,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles])
    else { return 0 }

    let root = source.standardizedFileURL.path
    var total: Int64 = 0
    for case let file as URL in walker {
      guard (try? file.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
      else { continue }
      if skippedExtensions.contains(file.pathExtension.lowercased()) { continue }
      var rel = file.standardizedFileURL.path
      guard rel.hasPrefix(root) else { continue }
      rel = String(rel.dropFirst(root.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      let target = dest.appendingPathComponent(rel)
      try fm.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
      try? fm.removeItem(at: target)
      try coordinatedCopy(file, to: target)
      let size = (try? fm.attributesOfItem(atPath: target.path)[.size] as? NSNumber)?.int64Value ?? 0
      total += size
    }
    return total
  }

  private static func coordinatedCopy(_ file: URL, to target: URL) throws {
    var coordError: NSError?
    var copyError: Error?
    NSFileCoordinator().coordinate(readingItemAt: file, options: [], error: &coordError) { readURL in
      do { try FileManager.default.copyItem(at: readURL, to: target) } catch { copyError = error }
    }
    if let error = coordError ?? copyError { throw error }
  }

  private static func readText(_ file: URL) -> String? {
    var text: String?
    var coordError: NSError?
    NSFileCoordinator().coordinate(readingItemAt: file, options: [], error: &coordError) { readURL in
      text = try? String(contentsOf: readURL, encoding: .utf8)
    }
    return text
  }
}
