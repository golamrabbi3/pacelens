import Flutter
import UIKit
import AVFoundation
import ARKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let methodChannelName = "pacelens/high_speed_camera"
  private let eventChannelName = "pacelens/high_speed_camera/status"
  private let videoInspectorChannelName = "pacelens/video_inspector"
  private let arDepthChannelName = "pacelens/ar_depth"
  private let arDepthSamplesChannelName = "pacelens/ar_depth/samples"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PaceLensCameraChannels") else {
      return
    }
    let messenger = registrar.messenger()
    FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger).setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "NO_APP_DELEGATE", message: "App delegate is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "getSupportedProfiles":
        result(self.supportedProfiles())
      case "initialize":
        result(nil)
      case "startRecording":
        result(FlutterError(
          code: "UNSUPPORTED_NATIVE_CAPTURE",
          message: "AVFoundation high-speed recording is not enabled in this MVP.",
          details: nil
        ))
      case "stopRecording":
        result(FlutterError(code: "NO_RECORDING", message: "No active native recording exists.", details: nil))
      case "dispose":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    FlutterMethodChannel(name: videoInspectorChannelName, binaryMessenger: messenger).setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "NO_APP_DELEGATE", message: "App delegate is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "inspectVideo":
        guard
          let arguments = call.arguments as? [String: Any],
          let uriString = arguments["uri"] as? String
        else {
          result(FlutterError(code: "MISSING_URI", message: "Video URI is required.", details: nil))
          return
        }
        do {
          result(try self.inspectVideo(uriString: uriString))
        } catch {
          result(FlutterError(code: "VIDEO_INSPECTION_FAILED", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    FlutterMethodChannel(name: arDepthChannelName, binaryMessenger: messenger).setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "NO_APP_DELEGATE", message: "App delegate is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "checkCapability":
        result(self.arDepthCapability())
      case "startSession":
        result(FlutterError(
          code: "UNSUPPORTED_AR_DEPTH",
          message: "ARKit depth sampling is not implemented in this build.",
          details: nil
        ))
      case "stopSession":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger).setStreamHandler(CameraStatusStreamHandler())
    FlutterEventChannel(name: arDepthSamplesChannelName, binaryMessenger: messenger).setStreamHandler(ArDepthSampleStreamHandler())
  }

  private func arDepthCapability() -> [String: Any] {
    let reason: String
    if #available(iOS 14.0, *) {
      let supportsSceneDepth = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
      reason = supportsSceneDepth
        ? "ARKit scene depth is available, but AR depth sampling is not implemented in this build."
        : "This device does not support ARKit scene depth."
    } else {
      reason = "ARKit scene depth requires iOS 14.0 or newer."
    }
    return [
      "supported": false,
      "reason": reason,
      "platform": "ios"
    ]
  }

  private func supportedProfiles() -> [[String: Any]] {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .builtInDualWideCamera, .builtInTripleCamera],
      mediaType: .video,
      position: .back
    )
    var profiles: [[String: Any]] = []
    for device in discovery.devices {
      for format in device.formats {
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        guard dimensions.width >= 1280 || dimensions.height >= 720 else { continue }
        for range in format.videoSupportedFrameRateRanges where range.maxFrameRate >= 60 {
          profiles.append([
            "cameraId": device.uniqueID,
            "width": Int(dimensions.width),
            "height": Int(dimensions.height),
            "minimumFps": range.minFrameRate,
            "maximumFps": range.maxFrameRate,
            "isHighSpeed": range.maxFrameRate >= 120,
            "supportsStableTimestamps": true
          ])
        }
      }
    }
    return profiles
  }

  private func inspectVideo(uriString: String) throws -> [String: Any?] {
    let url = URL(string: uriString) ?? URL(fileURLWithPath: uriString)
    let asset = AVAsset(url: url)
    guard let track = asset.tracks(withMediaType: .video).first else {
      throw NSError(domain: "PaceLens", code: 1, userInfo: [NSLocalizedDescriptionKey: "No video track found."])
    }

    let transformedSize = track.naturalSize.applying(track.preferredTransform)
    let width = Int(abs(transformedSize.width))
    let height = Int(abs(transformedSize.height))
    let durationSeconds = CMTimeGetSeconds(asset.duration)
    let durationUs = durationSeconds.isFinite ? Int64(durationSeconds * 1_000_000) : 0
    let timestamps = try samplePresentationTimestamps(asset: asset, track: track, limit: 1800)
    let diagnostics = timestampDiagnostics(timestamps)
    let computedFps: Double
    if let averageIntervalUs = diagnostics.averageIntervalUs, averageIntervalUs > 0 {
      computedFps = 1_000_000.0 / Double(averageIntervalUs)
    } else {
      computedFps = 0
    }
    let trackFps = Double(track.nominalFrameRate)
    let nominalFps = trackFps >= 1 ? trackFps : computedFps
    var warnings: [String] = []
    if nominalFps < 120 {
      warnings.append("120 FPS or higher is recommended.")
    }
    if nominalFps < 60 {
      warnings.append("Video below 60 FPS is not suitable for analysis.")
    }
    if !diagnostics.monotonic || diagnostics.duplicated || timestamps.count < 4 {
      warnings.append("Video timestamps are not reliable enough.")
    }
    if diagnostics.irregular {
      warnings.append("Video frame spacing is irregular; analysis must use timestamps.")
    }
    let hasStableTimestamps = diagnostics.monotonic && !diagnostics.duplicated && timestamps.count >= 4

    return [
      "uri": uriString,
      "width": width,
      "height": height,
      "nominalFps": nominalFps,
      "durationUs": durationUs,
      "hasStableTimestamps": hasStableTimestamps,
      "isLikelyReencoded": false,
      "sampledFrameCount": timestamps.count,
      "hasMonotonicTimestamps": diagnostics.monotonic,
      "hasDuplicatedTimestamps": diagnostics.duplicated,
      "hasIrregularFrameSpacing": diagnostics.irregular,
      "averageFrameIntervalUs": diagnostics.averageIntervalUs,
      "warnings": warnings
    ]
  }

  private func samplePresentationTimestamps(asset: AVAsset, track: AVAssetTrack, limit: Int) throws -> [Int64] {
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
    output.alwaysCopiesSampleData = false
    guard reader.canAdd(output) else {
      throw NSError(domain: "PaceLens", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot read video samples."])
    }
    reader.add(output)
    guard reader.startReading() else {
      throw reader.error ?? NSError(domain: "PaceLens", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot start video reader."])
    }
    var timestamps: [Int64] = []
    while timestamps.count < limit, let sample = output.copyNextSampleBuffer() {
      let time = CMSampleBufferGetPresentationTimeStamp(sample)
      let seconds = CMTimeGetSeconds(time)
      if seconds.isFinite {
        timestamps.append(Int64(seconds * 1_000_000))
      }
    }
    return timestamps
  }

  private struct TimestampDiagnostics {
    let monotonic: Bool
    let duplicated: Bool
    let irregular: Bool
    let averageIntervalUs: Int64?
  }

  private func timestampDiagnostics(_ timestamps: [Int64]) -> TimestampDiagnostics {
    guard timestamps.count >= 2 else {
      return TimestampDiagnostics(monotonic: false, duplicated: false, irregular: false, averageIntervalUs: nil)
    }
    var monotonic = true
    var duplicated = false
    var intervals: [Int64] = []
    for index in 1..<timestamps.count {
      let interval = timestamps[index] - timestamps[index - 1]
      if interval <= 0 {
        monotonic = false
      }
      if interval == 0 {
        duplicated = true
      }
      if interval > 0 {
        intervals.append(interval)
      }
    }
    guard !intervals.isEmpty else {
      return TimestampDiagnostics(monotonic: false, duplicated: duplicated, irregular: false, averageIntervalUs: nil)
    }
    let average = Int64(Double(intervals.reduce(0, +)) / Double(intervals.count))
    let sorted = intervals.sorted()
    let median = sorted[sorted.count / 2]
    let irregular = median > 0 && intervals.contains { abs($0 - median) > Int64(Double(median) * 0.35) }
    return TimestampDiagnostics(monotonic: monotonic, duplicated: duplicated, irregular: irregular, averageIntervalUs: average)
  }
}

final class CameraStatusStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    events([
      "kind": "idle",
      "message": "Camera capability channel is ready.",
      "motionScore": 0.0
    ])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}

final class ArDepthSampleStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    return FlutterError(
      code: "UNSUPPORTED_AR_DEPTH",
      message: "ARKit depth sampling is not implemented in this build.",
      details: nil
    )
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
