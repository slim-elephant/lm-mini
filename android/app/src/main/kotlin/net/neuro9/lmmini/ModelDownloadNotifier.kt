package net.neuro9.lmmini

import io.flutter.plugin.common.MethodChannel

/// Bridges Android model-download events to Flutter when the engine is alive.
object ModelDownloadNotifier {
    private const val CHANNEL = "net.neuro9.lmmini/model_download"

    @Volatile
    var messenger: io.flutter.plugin.common.BinaryMessenger? = null

    private var channel: MethodChannel? = null

    fun bind(binaryMessenger: io.flutter.plugin.common.BinaryMessenger) {
        messenger = binaryMessenger
        channel = MethodChannel(binaryMessenger, CHANNEL)
    }

    fun notifyProgress(
        jobId: String,
        bytesDownloaded: Long,
        bytesTotal: Long?,
        bytesPerSecond: Int,
    ) {
        val ch = channel ?: return
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            ch.invokeMethod(
                "onProgress",
                mapOf(
                    "jobId" to jobId,
                    "bytesDownloaded" to bytesDownloaded,
                    "bytesTotal" to bytesTotal,
                    "bytesPerSecond" to bytesPerSecond,
                ),
            )
        }
    }

    fun notifyComplete(jobId: String) {
        val ch = channel ?: return
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            ch.invokeMethod("onComplete", mapOf("jobId" to jobId))
        }
    }

    fun notifyError(jobId: String, message: String) {
        val ch = channel ?: return
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            ch.invokeMethod(
                "onError",
                mapOf("jobId" to jobId, "message" to message),
            )
        }
    }

    fun notifyCancelled(jobId: String) {
        val ch = channel ?: return
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            ch.invokeMethod("onCancelled", jobId)
        }
    }
}
