// OnDeviceSdBridge.swift
//
// Bridge between Flutter (lib/services/on_device_sd_endpoint.dart) and
// Apple's Core ML Stable Diffusion sources, vendored as the local SPM package
// ios/Packages/CoreMLStableDiffusion (renamed to avoid a target-name clash
// with mlx-swift-examples' StableDiffusion).
//
// Channels:
//   • MethodChannel("lm_mini/on_device_sd") → isAvailable / load / unload / generate / cancel
//   • EventChannel ("lm_mini/on_device_sd/progress") → step fraction 0…1
//
// SPM product `CoreMLStableDiffusion` is attached by
//   ios/scripts/add_stable_diffusion_to_runner.rb
// When the package is missing, every entry point returns `sd_not_bundled`
// so the Dart side can show a clear error without crashing the build.

import Flutter
import Foundation
import UIKit
import CoreML

final class OnDeviceSdBridge: NSObject {
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let progressHandler = OnDeviceSdProgressHandler()

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: "lm_mini/on_device_sd", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(
      name: "lm_mini/on_device_sd/progress", binaryMessenger: messenger)
    super.init()
    eventChannel.setStreamHandler(progressHandler)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(CoreMLStableDiffusion)
    if #available(iOS 16.2, *) {
      OnDeviceSdRunner.handle(
        call: call,
        result: result,
        progressSink: { [weak self] fraction in
          self?.progressHandler.send(fraction)
        })
      return
    }
    result(FlutterError(
      code: "sd_unsupported_os",
      message: "On-device Stable Diffusion requires iOS 16.2 or later.",
      details: nil))
    #else
    result(FlutterError(
      code: "sd_not_bundled",
      message: "CoreMLStableDiffusion local package is not added to the Runner target. "
        + "Run ios/scripts/add_stable_diffusion_to_runner.rb to attach ios/Packages/CoreMLStableDiffusion, then resolve packages.",
      details: nil))
    #endif
  }
}

private final class OnDeviceSdProgressHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func send(_ fraction: Double) {
    sink?(fraction)
  }
}

#if canImport(CoreMLStableDiffusion)
import CoreMLStableDiffusion

@available(iOS 16.2, *)
private enum OnDeviceSdRunner {
  private static var pipeline: (any StableDiffusionPipelineProtocol)?
  private static var loadedPath: String?
  private static var cancelRequested = false
  private static let lock = NSLock()

  static func handle(
    call: FlutterMethodCall,
    result: @escaping FlutterResult,
    progressSink: @escaping (Double) -> Void
  ) {
    switch call.method {
    case "isAvailable":
      result(true)

    case "load":
      guard let args = call.arguments as? [String: Any],
        let path = args["checkpointPath"] as? String
      else {
        result(FlutterError(
          code: "sd_bad_args", message: "checkpointPath required", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try loadPipeline(at: path)
          DispatchQueue.main.async { result(true) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "sd_load_failed",
              message: error.localizedDescription,
              details: nil))
          }
        }
      }

    case "unload":
      DispatchQueue.global(qos: .utility).async {
        unloadPipeline()
        DispatchQueue.main.async { result(true) }
      }

    case "cancel":
      lock.lock()
      cancelRequested = true
      lock.unlock()
      result(true)

    case "generate":
      guard let args = call.arguments as? [String: Any],
        let path = args["checkpointPath"] as? String,
        let prompt = args["prompt"] as? String
      else {
        result(FlutterError(
          code: "sd_bad_args",
          message: "checkpointPath and prompt required",
          details: nil))
        return
      }
      let negativePrompt = args["negativePrompt"] as? String ?? ""
      let steps = (args["steps"] as? NSNumber)?.intValue ?? 20
      let guidance = (args["guidanceScale"] as? NSNumber)?.doubleValue ?? 7.5
      let seedArg = (args["seed"] as? NSNumber)?.intValue
      let seed: UInt32 =
        seedArg == nil || seedArg! < 0
        ? UInt32.random(in: 0...UInt32.max)
        : UInt32(seedArg!)

      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try loadPipeline(at: path)
          lock.lock()
          cancelRequested = false
          let pipe = pipeline
          lock.unlock()
          guard let pipe else {
            throw NSError(
              domain: "OnDeviceSd", code: 1,
              userInfo: [NSLocalizedDescriptionKey: "Pipeline not loaded"])
          }

          var config = PipelineConfiguration(prompt: prompt)
          config.negativePrompt = negativePrompt
          config.stepCount = max(1, steps)
          config.guidanceScale = Float(guidance)
          config.seed = seed
          config.imageCount = 1
          config.disableSafety = true

          let images = try pipe.generateImages(configuration: config) { progress in
            let fraction =
              progress.stepCount > 0
              ? Double(progress.step + 1) / Double(progress.stepCount) : 0
            DispatchQueue.main.async { progressSink(min(1.0, fraction)) }
            lock.lock()
            let stop = cancelRequested
            lock.unlock()
            return !stop
          }

          guard let cgImage = images.first ?? nil else {
            throw NSError(
              domain: "OnDeviceSd", code: 2,
              userInfo: [
                NSLocalizedDescriptionKey:
                  cancelRequested
                  ? "Generation cancelled"
                  : "Pipeline returned no image (safety filter or empty output)"
              ])
          }

          let uiImage = UIImage(cgImage: cgImage)
          guard let png = uiImage.pngData() else {
            throw NSError(
              domain: "OnDeviceSd", code: 3,
              userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
          }

          let payload: [String: Any] = [
            "png": FlutterStandardTypedData(bytes: png),
            "seed": Int(seed),
            "width": cgImage.width,
            "height": cgImage.height,
          ]
          DispatchQueue.main.async { result(payload) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "sd_generate_failed",
              message: error.localizedDescription,
              details: nil))
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func loadPipeline(at path: String) throws {
    lock.lock()
    defer { lock.unlock() }
    if loadedPath == path, pipeline != nil { return }

    unloadPipelineLocked()

    let url = URL(fileURLWithPath: path, isDirectory: true)
    let config = MLModelConfiguration()
#if targetEnvironment(simulator)
    // ANE is unavailable in Simulator; cpuAndNeuralEngine often fails to load.
    config.computeUnits = .cpuOnly
#else
    config.computeUnits = .cpuAndNeuralEngine
#endif

    let isXL = FileManager.default.fileExists(
      atPath: url.appendingPathComponent("TextEncoder2.mlmodelc").path)

    if isXL {
      if #available(iOS 17.0, *) {
        var xl = try StableDiffusionXLPipeline(
          resourcesAt: url,
          configuration: config,
          reduceMemory: true)
        try xl.loadResources()
        pipeline = xl
        loadedPath = path
      } else {
        throw NSError(
          domain: "OnDeviceSd", code: 4,
          userInfo: [
            NSLocalizedDescriptionKey:
              "SDXL models require iOS 17.0 or later. Use SD 1.5 or 2.1 on this device."
          ])
      }
    } else {
      var sd = try StableDiffusionPipeline(
        resourcesAt: url,
        controlNet: [],
        configuration: config,
        disableSafety: true,
        reduceMemory: true)
      try sd.loadResources()
      pipeline = sd
      loadedPath = path
    }
  }

  private static func unloadPipeline() {
    lock.lock()
    defer { lock.unlock() }
    unloadPipelineLocked()
  }

  private static func unloadPipelineLocked() {
    if let pipe = pipeline {
      // Both SD and SDXL conform to ResourceManaging via protocol extensions.
      pipe.unloadResources()
    }
    pipeline = nil
    loadedPath = nil
  }
}
#endif
