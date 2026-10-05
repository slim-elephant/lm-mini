// MLXBridge.swift
//
// Bridge between Flutter (lib/services/on_device_mlx_endpoint.dart) and
// Apple Silicon's MLX-Swift runtime on macOS.
//
// Channels:
//   • MethodChannel("lm_mini/mlx")  → load / unload / cancel
//   • EventChannel ("lm_mini/mlx/stream") → token stream
//
// SPM packages are attached by macos/scripts/add_mlx_to_runner.rb (idempotent).
// Pinned to the same versions as iOS for a single known-good matrix:
//   mlx-swift          == 0.25.6
//   mlx-swift-examples == 2.25.9

import FlutterMacOS
import Foundation

// MARK: - Public bridge (always available, no @available)

final class MLXBridge: NSObject {
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let streamHandler = MLXStreamHandler()

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "lm_mini/mlx", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(
      name: "lm_mini/mlx/stream", binaryMessenger: messenger)
    super.init()
    eventChannel.setStreamHandler(streamHandler)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(MLXLLM) && canImport(MLXLMCommon)
    if #available(macOS 14.0, *) {
      MLXRunner.handle(call: call, result: result)
      return
    }
    result(FlutterError(
      code: "mlx_unsupported_os",
      message: "MLX requires macOS 14.0 or later.",
      details: nil))
    #else
    result(FlutterError(
      code: "mlx_not_bundled",
      message: "MLX-Swift SPM packages are not added to the Runner target. "
             + "Run macos/scripts/add_mlx_to_runner.rb and rebuild.",
      details: nil))
    #endif
  }
}

// MARK: - Stream handler

private final class MLXStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?,
                eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    #if canImport(MLXLLM) && canImport(MLXLMCommon)
    if #available(macOS 14.0, *) {
      MLXRunner.stream(arguments: arguments, sink: events)
      return nil
    }
    events(FlutterError(
      code: "mlx_unsupported_os",
      message: "MLX requires macOS 14.0 or later.",
      details: nil))
    events(FlutterEndOfEventStream)
    return nil
    #else
    events(FlutterError(
      code: "mlx_not_bundled",
      message: "MLX-Swift SPM packages are not added to the Runner target.",
      details: nil))
    events(FlutterEndOfEventStream)
    return nil
    #endif
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // Only drop the sink here. Flutter may pair onCancel/onListen when
    // replacing subscriptions; cancelling generation here races the new
    // stream and yields empty output. Explicit stop uses method "cancel".
    sink = nil
    return nil
  }
}

// MARK: - MLX-only runtime

#if canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom

@available(macOS 14.0, *)
fileprivate enum MLXRunner {
  fileprivate static var loadedContext: ModelContext?
  fileprivate static var loadedPath: String?
  fileprivate static var activeGeneration: Task<Void, Never>?
  fileprivate static var generationEpoch: UInt64 = 0

  static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "load":
      guard let args = call.arguments as? [String: Any],
            let path = args["modelPath"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "modelPath required",
                            details: nil))
        return
      }
      NSLog("🧠 MLX load request path=%@", path)
      Task {
        do {
          try await loadModel(at: path)
          NSLog("🧠 MLX load complete path=%@", path)
          await MainActor.run { result(nil) }
        } catch {
          NSLog("🧠 MLX load failed path=%@ error=%@", path,
                String(describing: error))
          await MainActor.run {
            result(FlutterError(code: "load_failed",
                                message: error.localizedDescription,
                                details: nil))
          }
        }
      }

    case "cancel":
      cancel()
      result(nil)

    case "unload":
      cancel()
      loadedContext = nil
      loadedPath = nil
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// `Jinja.TemplateException.message` is internal, so `localizedDescription`
  /// collapses to "The operation couldn’t be completed. (Jinja.TemplateException
  /// error 1.)" and drops the template's own sentence.
  static func inferenceErrorMessage(_ error: Error) -> String {
    let typeName = String(reflecting: type(of: error))
    if typeName.contains("TemplateException") {
      for child in Mirror(reflecting: error).children where child.label == "message" {
        let inner = Mirror(reflecting: child.value)
        if inner.displayStyle == .optional,
           let value = inner.children.first?.value as? String,
           !value.isEmpty {
          return value
        }
      }
    }
    return error.localizedDescription
  }

  static func stream(arguments: Any?, sink: @escaping FlutterEventSink) {
    guard let args = arguments as? [String: Any]
    else {
      sink(FlutterError(code: "bad_args",
                        message: "arguments map required", details: nil))
      sink(FlutterEndOfEventStream)
      return
    }
    let maxTokens = (args["maxTokens"] as? Int) ?? 1024
    let temperature = (args["temperature"] as? Double) ?? 0.7
    let topP = (args["topP"] as? Double) ?? 0.95
    let repetitionPenalty = (args["repetitionPenalty"] as? Double) ?? 1.1

    let imagePaths = (args["imagePaths"] as? [String]) ?? []
    let images: [UserInput.Image] = imagePaths.compactMap { path in
      let url = URL(fileURLWithPath: path)
      return FileManager.default.fileExists(atPath: path) ? .url(url) : nil
    }
    if !imagePaths.isEmpty {
      NSLog("🧠 MLX stream images requested=%d resolved=%d",
            imagePaths.count, images.count)
    }

    let userInput: UserInput
    if let rawMessages = args["messages"] as? [[String: Any]] {
      let messages: [[String: String]] = rawMessages.compactMap { m in
        guard let role = m["role"] as? String,
              let content = m["content"] as? String else { return nil }
        return ["role": role, "content": content]
      }
      NSLog("🧠 MLX stream messages=%d roles=%@",
            messages.count,
            messages.map { $0["role"] ?? "?" }.joined(separator: ","))
      userInput = UserInput(messages: messages, images: images)
    } else if let prompt = args["prompt"] as? String {
      userInput = UserInput(prompt: prompt, images: images)
    } else {
      sink(FlutterError(code: "bad_args",
                        message: "prompt or messages required",
                        details: nil))
      sink(FlutterEndOfEventStream)
      return
    }

    activeGeneration?.cancel()
    generationEpoch &+= 1
    let epoch = generationEpoch
    activeGeneration = Task {
      guard let context = loadedContext else {
        NSLog("🧠 MLX stream rejected: model not loaded")
        await MainActor.run {
          sink(FlutterError(code: "not_loaded",
                            message: "Call load() first",
                            details: nil))
          sink(FlutterEndOfEventStream)
        }
        return
      }
      if Task.isCancelled || epoch != generationEpoch {
        NSLog("🧠 MLX stream aborted before begin (cancelled/stale epoch)")
        await MainActor.run { sink(FlutterEndOfEventStream) }
        return
      }
      NSLog("🧠 MLX stream begin maxTokens=%d temp=%.2f topP=%.2f repPenalty=%.2f epoch=%llu",
            maxTokens, temperature, topP, repetitionPenalty, epoch)
      do {
        let params = GenerateParameters(
          maxTokens: maxTokens,
          temperature: Float(temperature),
          topP: Float(topP),
          repetitionPenalty: Float(repetitionPenalty))
        let input = try await context.processor.prepare(input: userInput)
        let promptCount = input.text.tokens.shape[0]
        NSLog("🧠 MLX prompt tokens=%d", promptCount)
        var produced: [Int] = []
        var lastEmitted = ""
        var chunks = 0
        let eosId = context.tokenizer.eosTokenId
        let result = try MLXLMCommon.generate(
          input: input,
          parameters: params,
          context: context
        ) { tokens in
          if Task.isCancelled || epoch != generationEpoch { return .stop }
          if tokens.count > produced.count {
            if produced.isEmpty, let first = tokens.first {
              NSLog("🧠 MLX first token id=%d eosId=%@",
                    first,
                    eosId.map { String($0) } ?? "nil")
            }
            produced = tokens
            let decoded = context.tokenizer.decode(tokens: produced)
            if decoded.count > lastEmitted.count {
              let piece = String(decoded[lastEmitted.endIndex...])
              lastEmitted = decoded
              chunks += 1
              DispatchQueue.main.async {
                if epoch == generationEpoch { sink(piece) }
              }
            }
            if let eosId, let last = tokens.last, last == eosId {
              return .stop
            }
          }
          return tokens.count >= maxTokens ? .stop : .more
        }
        _ = result
        NSLog(
          "🧠 MLX stream done tokens=%d chunks=%d chars=%d cancelled=%d",
          produced.count, chunks, lastEmitted.count, Task.isCancelled ? 1 : 0)
        if produced.isEmpty && !Task.isCancelled && epoch == generationEpoch {
          NSLog("🧠 MLX empty generation — model returned no tokens (check chat template / EOS)")
        }
      } catch {
        let message = inferenceErrorMessage(error)
        NSLog("🧠 MLX inference_failed: %@", message)
        await MainActor.run {
          if epoch == generationEpoch {
            sink(FlutterError(code: "inference_failed",
                              message: message,
                              details: nil))
          }
        }
      }
      await MainActor.run {
        if epoch == generationEpoch {
          sink(FlutterEndOfEventStream)
        }
      }
    }
  }

  static func cancel() {
    NSLog("🧠 MLX cancel")
    generationEpoch &+= 1
    activeGeneration?.cancel()
    activeGeneration = nil
  }

  /// See ios/Runner/MLXBridge.swift. Gemma 3 4B+ `text_config` omits KV
  /// heads and vocab; the text loader's 1B defaults then reject the weights.
  static func repairGemma3TextConfig(at directory: URL) {
    let configURL = directory.appendingPathComponent("config.json")
    guard let data = try? Data(contentsOf: configURL),
          var root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return }

    let modelType = root["model_type"] as? String ?? ""
    let nested = root["text_config"] is [String: Any]
    guard modelType == "gemma3" || modelType == "gemma3_text" || nested else {
      return
    }

    var text = (root["text_config"] as? [String: Any]) ?? root
    let hidden = (text["hidden_size"] as? NSNumber)?.intValue ?? 0
    var changed = false
    func fill(_ key: String, _ value: Int) {
      if text[key] == nil {
        text[key] = value
        changed = true
      }
    }

    switch hidden {
    case 2560:
      fill("num_attention_heads", 8)
      fill("num_key_value_heads", 4)
      fill("head_dim", 256)
      fill("vocab_size", 262208)
    case 3840:
      fill("num_attention_heads", 16)
      fill("num_key_value_heads", 8)
      fill("head_dim", 256)
      fill("vocab_size", 262208)
    case 5376:
      fill("vocab_size", 262208)
    default:
      break
    }

    guard changed else { return }
    if nested {
      root["text_config"] = text
    } else {
      root = text
    }
    guard let out = try? JSONSerialization.data(
      withJSONObject: root, options: [.prettyPrinted])
    else { return }
    do {
      try out.write(to: configURL, options: .atomic)
      NSLog("🧠 MLX repaired Gemma 3 text_config hidden=%d", hidden)
    } catch {
      NSLog("🧠 MLX Gemma 3 config repair failed: %@",
            error.localizedDescription)
    }
  }

  static func loadModel(at path: String) async throws {
    if loadedPath == path, loadedContext != nil {
      NSLog("🧠 MLX loadModel cache hit: %@", path)
      return
    }
    MLXRandom.seed(0)
    let url = URL(fileURLWithPath: path)
    repairGemma3TextConfig(at: url)
    var isDir: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: path,
                                                isDirectory: &isDir)
    NSLog("🧠 MLX loadModel: path=%@ exists=%d isDir=%d",
          path, exists ? 1 : 0, isDir.boolValue ? 1 : 0)
    let config = ModelConfiguration(directory: url)
    let context = try await LLMModelFactory.shared.load(
      configuration: config) { _ in }
    loadedContext = context
    loadedPath = path
    NSLog("🧠 MLX loadModel: model context ready")
  }
}
#endif
