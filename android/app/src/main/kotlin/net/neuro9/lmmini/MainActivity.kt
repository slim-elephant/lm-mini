package net.neuro9.lmmini

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val LIVE_ACTIVITY_CHANNEL = "net.neuro9.lmmini/liveactivity"
        private const val DEEP_LINK_CHANNEL = "net.neuro9.lmmini/deeplink"
        private const val AUDIO_DECODE_CHANNEL = "net.neuro9.lmmini/audio_decode"
        private const val MODEL_DOWNLOAD_CHANNEL = "net.neuro9.lmmini/model_download"
        private const val DEVICE_CAPABILITY_CHANNEL = "net.neuro9.lmmini/device_capability"
    }

    private var deepLinkChannel: MethodChannel? = null
    private var pendingAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GenerationForegroundService.ensureChannel(this)
        ModelDownloadForegroundService.ensureChannel(this)
        ModelDownloadNotifier.bind(flutterEngine.dartExecutor.binaryMessenger)

        deepLinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEEP_LINK_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialAction" -> {
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    else -> result.notImplemented()
                }
            }
        }

        pendingAction?.let { dispatchDeepLink(it) }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_DECODE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "convertToWav" -> {
                        val args = call.arguments as? Map<*, *>
                        val sourcePath = args?.get("sourcePath") as? String
                        val outputPath = args?.get("outputPath") as? String
                        val sampleRate = (args?.get("sampleRate") as? Number)?.toInt() ?: 16000
                        if (sourcePath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "sourcePath and outputPath required", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                val out = AudioDecodeHelper.convertToWav(
                                    sourcePath,
                                    outputPath,
                                    sampleRate,
                                )
                                runOnUiThread { result.success(out) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("DECODE_FAILED", e.message, null)
                                }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MODEL_DOWNLOAD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(true)
                    "startDownload" -> {
                        val args = call.arguments as? Map<*, *>
                        val jobId = args?.get("jobId") as? String
                        val displayName = args?.get("displayName") as? String ?: "Download"
                        val url = args?.get("url") as? String
                        val partialPath = args?.get("partialPath") as? String
                        if (jobId.isNullOrBlank() || url.isNullOrBlank() ||
                            partialPath.isNullOrBlank()
                        ) {
                            result.error("INVALID_ARGS", "Missing download args", null)
                            return@setMethodCallHandler
                        }
                        ModelDownloadForegroundService.start(
                            this,
                            jobId,
                            displayName,
                            url,
                            partialPath,
                        )
                        result.success(null)
                    }
                    "cancelDownload" -> {
                        val args = call.arguments as? Map<*, *>
                        val jobId = args?.get("jobId") as? String
                        if (jobId.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "jobId required", null)
                            return@setMethodCallHandler
                        }
                        ModelDownloadForegroundService.cancel(this, jobId)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CAPABILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidProfile" -> result.success(androidProfileMap())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIVE_ACTIVITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(canShowGenerationNotification())
                    "startActivity" -> {
                        val args = call.arguments as? Map<*, *>
                        val modelName = args?.get("modelName") as? String ?: "AI Model"
                        val kind = args?.get("kind") as? String ?: "chat"
                        if (!canShowGenerationNotification()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        GenerationForegroundService.start(this, modelName, "Chat", kind)
                        result.success(true)
                    }
                    "updateActivity" -> {
                        val args = call.arguments as? Map<*, *>
                        val modelName = args?.get("modelName") as? String ?: "AI Model"
                        val statusText = args?.get("statusText") as? String ?: "Generating…"
                        val tokenCount = (args?.get("tokenCount") as? Number)?.toInt() ?: 0
                        val tokensPerSecond =
                            (args?.get("tokensPerSecond") as? Number)?.toDouble() ?: 0.0
                        val kind = args?.get("kind") as? String ?: "chat"
                        val progress = (args?.get("progress") as? Number)?.toDouble() ?: 0.0
                        GenerationForegroundService.update(
                            this,
                            modelName,
                            statusText,
                            tokenCount,
                            tokensPerSecond,
                            kind,
                            progress,
                        )
                        result.success(null)
                    }
                    "endActivity" -> {
                        GenerationForegroundService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleIntent(intent: Intent?) {
        val uri = intent?.data ?: return
        DeepLinkHandler.parse(uri)?.let { dispatchDeepLink(it) }
    }

    private fun dispatchDeepLink(action: String) {
        val channel = deepLinkChannel
        if (channel != null) {
            channel.invokeMethod("handleAction", action)
            pendingAction = null
        } else {
            pendingAction = action
        }
    }

    private fun canShowGenerationNotification(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun androidProfileMap(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mem = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mem)
        val ramGb = mem.totalMem.toDouble() / (1024.0 * 1024.0 * 1024.0)
        val vulkan =
            packageManager.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL) ||
                packageManager.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_VERSION)
        val soc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Build.SOC_MODEL.ifBlank { Build.HARDWARE }
        } else {
            Build.HARDWARE
        }
        return mapOf(
            "ramGb" to ramGb,
            "supportsVulkan" to vulkan,
            "soc" to soc,
            "hardware" to Build.HARDWARE,
        )
    }
}
