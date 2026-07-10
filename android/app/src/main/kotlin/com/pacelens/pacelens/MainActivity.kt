package com.pacelens.pacelens

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.params.StreamConfigurationMap
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.util.Range
import android.util.Size
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    private val methodChannelName = "pacelens/high_speed_camera"
    private val eventChannelName = "pacelens/high_speed_camera/status"
    private val videoInspectorChannelName = "pacelens/video_inspector"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSupportedProfiles" -> result.success(getSupportedProfiles())
                "initialize" -> {
                    eventSink?.success(status("unsupported", "Native recording is not enabled in this MVP.", 0.0))
                    result.success(null)
                }
                "startRecording" -> result.error(
                    "UNSUPPORTED_NATIVE_CAPTURE",
                    "Camera2 high-speed recording requires a device-specific capture implementation.",
                    null
                )
                "stopRecording" -> result.error(
                    "NO_RECORDING",
                    "No active native recording exists.",
                    null
                )
                "dispose" -> {
                    eventSink = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, videoInspectorChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "inspectVideo" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString == null) {
                        result.error("MISSING_URI", "Video URI is required.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(inspectVideo(uriString))
                    } catch (error: Throwable) {
                        result.error("VIDEO_INSPECTION_FAILED", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    eventSink?.success(status("idle", "Camera capability channel is ready.", 0.0))
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun getSupportedProfiles(): List<Map<String, Any>> {
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val profiles = mutableListOf<Map<String, Any>>()
        for (cameraId in manager.cameraIdList) {
            val characteristics = manager.getCameraCharacteristics(cameraId)
            val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
            if (facing != CameraCharacteristics.LENS_FACING_BACK) {
                continue
            }
            val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP) ?: continue
            profiles.addAll(highSpeedProfiles(cameraId, map))
            profiles.addAll(standardProfiles(cameraId, characteristics))
        }
        return profiles
            .distinctBy { "${it["cameraId"]}-${it["width"]}-${it["height"]}-${it["maximumFps"]}-${it["isHighSpeed"]}" }
            .filter { (it["maximumFps"] as Double) >= 60.0 }
    }

    private fun highSpeedProfiles(cameraId: String, map: StreamConfigurationMap): List<Map<String, Any>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return emptyList()
        }
        val profiles = mutableListOf<Map<String, Any>>()
        for (size in map.highSpeedVideoSizes) {
            for (range in map.getHighSpeedVideoFpsRangesFor(size)) {
                profiles.add(profile(cameraId, size, range, true))
            }
        }
        return profiles
    }

    private fun standardProfiles(
        cameraId: String,
        characteristics: CameraCharacteristics
    ): List<Map<String, Any>> {
        val ranges = characteristics.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
            ?: return emptyList()
        val candidateSizes = listOf(Size(1920, 1080), Size(1280, 720))
        val profiles = mutableListOf<Map<String, Any>>()
        for (range in ranges) {
            if (range.upper >= 60) {
                for (size in candidateSizes) {
                    profiles.add(profile(cameraId, size, range, false))
                }
            }
        }
        return profiles
    }

    private fun profile(
        cameraId: String,
        size: Size,
        range: Range<Int>,
        isHighSpeed: Boolean
    ): Map<String, Any> {
        return mapOf(
            "cameraId" to cameraId,
            "width" to size.width,
            "height" to size.height,
            "minimumFps" to range.lower.toDouble(),
            "maximumFps" to range.upper.toDouble(),
            "isHighSpeed" to isHighSpeed,
            "supportsStableTimestamps" to true
        )
    }

    private fun status(kind: String, message: String, motionScore: Double): Map<String, Any> {
        return mapOf(
            "kind" to kind,
            "message" to message,
            "motionScore" to motionScore
        )
    }

    private fun inspectVideo(uriString: String): Map<String, Any?> {
        val uri = Uri.parse(uriString)
        val retriever = MediaMetadataRetriever()
        val extractor = MediaExtractor()
        try {
            retriever.setDataSource(this, uri)
            extractor.setDataSource(this, uri, null)
            val trackIndex = findVideoTrack(extractor)
                ?: throw IllegalArgumentException("No video track found.")
            extractor.selectTrack(trackIndex)
            val format = extractor.getTrackFormat(trackIndex)
            val width = metadataInt(retriever, MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                ?: format.optionalInt(MediaFormat.KEY_WIDTH)
                ?: 0
            val height = metadataInt(retriever, MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                ?: format.optionalInt(MediaFormat.KEY_HEIGHT)
                ?: 0
            val durationUs = (metadataLong(retriever, MediaMetadataRetriever.METADATA_KEY_DURATION) ?: 0L) * 1000L
            val formatFps = format.optionalInt(MediaFormat.KEY_FRAME_RATE)?.toDouble() ?: 0.0
            val timestamps = samplePresentationTimestamps(extractor, 1800)
            val diagnostics = timestampDiagnostics(timestamps)
            val computedFps = diagnostics.averageIntervalUs?.let {
                if (it > 0) 1_000_000.0 / it else 0.0
            } ?: 0.0
            val captureFps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)?.toDoubleOrNull() ?: 0.0
            } else {
                0.0
            }
            val nominalFps = listOf(captureFps, formatFps, computedFps).firstOrNull { it >= 1.0 } ?: 0.0
            val warnings = mutableListOf<String>()
            if (nominalFps < 120.0) warnings.add("120 FPS or higher is recommended.")
            if (nominalFps < 60.0) warnings.add("Video below 60 FPS is not suitable for analysis.")
            if (!diagnostics.monotonic || diagnostics.duplicated || timestamps.size < 4) {
                warnings.add("Video timestamps are not reliable enough.")
            }
            if (diagnostics.irregular) warnings.add("Video frame spacing is irregular; analysis must use timestamps.")
            val isLikelyReencoded = formatFps > 0.0 && captureFps > 0.0 && abs(formatFps - captureFps) > 5.0
            if (isLikelyReencoded) warnings.add("The imported video may have been re-encoded.")
            val hasStableTimestamps = diagnostics.monotonic && !diagnostics.duplicated && timestamps.size >= 4
            return mapOf(
                "uri" to uriString,
                "width" to width,
                "height" to height,
                "nominalFps" to nominalFps,
                "durationUs" to durationUs,
                "hasStableTimestamps" to hasStableTimestamps,
                "isLikelyReencoded" to isLikelyReencoded,
                "sampledFrameCount" to timestamps.size,
                "hasMonotonicTimestamps" to diagnostics.monotonic,
                "hasDuplicatedTimestamps" to diagnostics.duplicated,
                "hasIrregularFrameSpacing" to diagnostics.irregular,
                "averageFrameIntervalUs" to diagnostics.averageIntervalUs,
                "warnings" to warnings
            )
        } finally {
            extractor.release()
            retriever.release()
        }
    }

    private fun findVideoTrack(extractor: MediaExtractor): Int? {
        for (index in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(index)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("video/") == true) return index
        }
        return null
    }

    private fun samplePresentationTimestamps(extractor: MediaExtractor, limit: Int): List<Long> {
        val timestamps = mutableListOf<Long>()
        while (timestamps.size < limit) {
            val sampleTime = extractor.sampleTime
            if (sampleTime < 0) break
            timestamps.add(sampleTime)
            if (!extractor.advance()) break
        }
        return timestamps
    }

    private data class TimestampDiagnostics(
        val monotonic: Boolean,
        val duplicated: Boolean,
        val irregular: Boolean,
        val averageIntervalUs: Long?
    )

    private fun timestampDiagnostics(timestamps: List<Long>): TimestampDiagnostics {
        if (timestamps.size < 2) {
            return TimestampDiagnostics(monotonic = false, duplicated = false, irregular = false, averageIntervalUs = null)
        }
        var monotonic = true
        var duplicated = false
        val intervals = mutableListOf<Long>()
        for (index in 1 until timestamps.size) {
            val interval = timestamps[index] - timestamps[index - 1]
            if (interval <= 0) monotonic = false
            if (interval == 0L) duplicated = true
            if (interval > 0) intervals.add(interval)
        }
        if (intervals.isEmpty()) {
            return TimestampDiagnostics(monotonic = false, duplicated = duplicated, irregular = false, averageIntervalUs = null)
        }
        val average = intervals.average().toLong()
        val median = intervals.sorted()[intervals.size / 2]
        val irregular = median > 0 && intervals.any { abs(it - median) > median * 0.35 }
        return TimestampDiagnostics(monotonic, duplicated, irregular, average)
    }

    private fun MediaFormat.optionalInt(key: String): Int? {
        return if (containsKey(key)) getInteger(key) else null
    }

    private fun metadataInt(retriever: MediaMetadataRetriever, key: Int): Int? {
        return retriever.extractMetadata(key)?.toIntOrNull()
    }

    private fun metadataLong(retriever: MediaMetadataRetriever, key: Int): Long? {
        return retriever.extractMetadata(key)?.toLongOrNull()
    }
}
