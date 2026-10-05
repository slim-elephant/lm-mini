package net.neuro9.lmmini

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/// Foreground service that downloads model files with resume support and keeps
/// transfers alive when the user leaves the app.
class ModelDownloadForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "lmmini_download"
        const val NOTIFICATION_ID = 9002

        const val ACTION_START = "net.neuro9.lmmini.download.START"
        const val ACTION_CANCEL = "net.neuro9.lmmini.download.CANCEL"

        const val EXTRA_JOB_ID = "jobId"
        const val EXTRA_DISPLAY_NAME = "displayName"
        const val EXTRA_URL = "url"
        const val EXTRA_PARTIAL_PATH = "partialPath"

        @Volatile
        private var activeJobId: String? = null

        private val cancelFlags = mutableMapOf<String, AtomicBoolean>()

        fun start(
            context: Context,
            jobId: String,
            displayName: String,
            url: String,
            partialPath: String,
        ) {
            cancelFlags[jobId] = AtomicBoolean(false)
            activeJobId = jobId
            val intent = Intent(context, ModelDownloadForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_JOB_ID, jobId)
                putExtra(EXTRA_DISPLAY_NAME, displayName)
                putExtra(EXTRA_URL, url)
                putExtra(EXTRA_PARTIAL_PATH, partialPath)
            }
            context.startForegroundService(intent)
        }

        fun cancel(context: Context, jobId: String) {
            cancelFlags[jobId]?.set(true)
            val intent = Intent(context, ModelDownloadForegroundService::class.java).apply {
                action = ACTION_CANCEL
                putExtra(EXTRA_JOB_ID, jobId)
            }
            context.startService(intent)
        }

        fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL_ID) != null) return
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Model downloads",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows progress while models download in the background"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private var displayName: String = "Downloading model"
    private var jobId: String = ""
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                jobId = intent.getStringExtra(EXTRA_JOB_ID) ?: return START_NOT_STICKY
                displayName = intent.getStringExtra(EXTRA_DISPLAY_NAME) ?: displayName
                val url = intent.getStringExtra(EXTRA_URL) ?: return START_NOT_STICKY
                val partialPath =
                    intent.getStringExtra(EXTRA_PARTIAL_PATH) ?: return START_NOT_STICKY

                ensureChannel(this)
                promoteToForeground(buildNotification("Starting…", 0))
                acquireLocks()

                thread(name = "ModelDownload-$jobId") {
                    runDownload(jobId, displayName, url, partialPath)
                }
            }

            ACTION_CANCEL -> {
                val id = intent.getStringExtra(EXTRA_JOB_ID) ?: jobId
                cancelFlags[id]?.set(true)
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releaseLocks()
        super.onDestroy()
    }

    private fun runDownload(
        jobId: String,
        displayName: String,
        urlString: String,
        partialPath: String,
    ) {
        val cancelFlag = cancelFlags.getOrPut(jobId) { AtomicBoolean(false) }
        var lastSpeedSampleAt = 0L
        var lastSpeedBytes = 0L
        var lastProgressNotifyAt = 0L
        var bytesPerSecond = 0

        try {
            val partialFile = File(partialPath)
            partialFile.parentFile?.mkdirs()

            var resolvedUrl = urlString
            var existingBytes = if (partialFile.exists()) partialFile.length() else 0L

            for (redirect in 0 until 6) {
                if (cancelFlag.get()) throw CancelledException()
                val url = URL(resolvedUrl)
                val connection = (url.openConnection() as HttpURLConnection).apply {
                    connectTimeout = 30_000
                    readTimeout = 60_000
                    instanceFollowRedirects = false
                    if (existingBytes > 0) {
                        setRequestProperty("Range", "bytes=$existingBytes-")
                    }
                }

                val code = connection.responseCode
                when {
                    code in 300..399 -> {
                        resolvedUrl = connection.getHeaderField("Location")
                            ?: throw IllegalStateException("Redirect without location")
                        connection.disconnect()
                        existingBytes = 0
                        continue
                    }

                    code == HttpURLConnection.HTTP_PARTIAL -> {
                        // Resume OK
                    }

                    code == HttpURLConnection.HTTP_OK -> {
                        if (existingBytes > 0) {
                            // Server ignored Range — restart file.
                            partialFile.delete()
                            existingBytes = 0
                        }
                    }

                    else -> throw IllegalStateException("HTTP $code")
                }

                val totalHeader = connection.contentLengthLong
                val bytesTotal = when {
                    totalHeader > 0 && code == HttpURLConnection.HTTP_PARTIAL ->
                        existingBytes + totalHeader
                    connection.getHeaderField("Content-Range")?.substringAfter('/')?.toLongOrNull() != null ->
                        connection.getHeaderField("Content-Range")!!.substringAfter('/').toLong()
                    totalHeader > 0 -> totalHeader
                    else -> -1L
                }

                val input: InputStream = connection.inputStream
                FileOutputStream(partialFile, existingBytes > 0).use { output ->
                    val buffer = ByteArray(64 * 1024)
                    var downloaded = existingBytes
                    var read: Int
                    while (input.read(buffer).also { read = it } != -1) {
                        if (cancelFlag.get()) throw CancelledException()
                        output.write(buffer, 0, read)
                        downloaded += read

                        val now = System.currentTimeMillis()
                        if (now - lastSpeedSampleAt >= 500) {
                            if (lastSpeedSampleAt > 0) {
                                val delta = downloaded - lastSpeedBytes
                                val elapsed = now - lastSpeedSampleAt
                                if (elapsed > 0) {
                                    bytesPerSecond = (delta * 1000 / elapsed).toInt()
                                }
                            }
                            lastSpeedSampleAt = now
                            lastSpeedBytes = downloaded
                        }

                        // Throttle Flutter/UI progress to ~4 Hz. Notifying on every
                        // 64 KiB chunk floods the main isolate and used to freeze the
                        // download FAB label (speed clock reset the paint throttle).
                        val shouldNotify = now - lastProgressNotifyAt >= 250
                        if (shouldNotify) {
                            lastProgressNotifyAt = now
                            val progressPct = if (bytesTotal > 0) {
                                ((downloaded * 100) / bytesTotal).toInt().coerceIn(0, 100)
                            } else 0

                            updateNotification(
                                if (bytesTotal > 0) "$progressPct%" else "Downloading…",
                                progressPct,
                            )
                            ModelDownloadNotifier.notifyProgress(
                                jobId,
                                downloaded,
                                if (bytesTotal > 0) bytesTotal else null,
                                bytesPerSecond,
                            )
                        }
                    }
                }
                connection.disconnect()
                // Final progress tick so UI reaches 100% before complete.
                ModelDownloadNotifier.notifyProgress(
                    jobId,
                    partialFile.length(),
                    if (bytesTotal > 0) bytesTotal else partialFile.length(),
                    bytesPerSecond,
                )
                ModelDownloadNotifier.notifyComplete(jobId)
                break
            }
        } catch (e: CancelledException) {
            ModelDownloadNotifier.notifyCancelled(jobId)
        } catch (e: Exception) {
            ModelDownloadNotifier.notifyError(jobId, e.message ?: e.toString())
        } finally {
            cancelFlags.remove(jobId)
            if (activeJobId == jobId) activeJobId = null
            releaseLocks()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private class CancelledException : Exception()

    private fun updateNotification(statusText: String, progressPct: Int) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(
            NOTIFICATION_ID,
            buildNotification(statusText, progressPct),
        )
    }

    private fun buildNotification(statusText: String, progressPct: Int): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(displayName)
            .setContentText(statusText)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setProgress(100, progressPct.coerceIn(0, 100), progressPct <= 0)
            .build()
    }

    private fun promoteToForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun acquireLocks() {
        try {
            if (wakeLock == null) {
                val pm = getSystemService(POWER_SERVICE) as PowerManager
                wakeLock = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "lmmini:download",
                ).apply { setReferenceCounted(false) }
            }
            wakeLock?.let { if (!it.isHeld) it.acquire(6 * 60 * 60 * 1000L) }
        } catch (_: Exception) {
        }
        try {
            if (wifiLock == null) {
                val wm = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
                val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    WifiManager.WIFI_MODE_FULL_LOW_LATENCY
                } else {
                    @Suppress("DEPRECATION")
                    WifiManager.WIFI_MODE_FULL_HIGH_PERF
                }
                wifiLock = wm.createWifiLock(mode, "lmmini:download").apply {
                    setReferenceCounted(false)
                }
            }
            wifiLock?.let { if (!it.isHeld) it.acquire() }
        } catch (_: Exception) {
        }
    }

    private fun releaseLocks() {
        try {
            wakeLock?.let { if (it.isHeld) it.release() }
        } catch (_: Exception) {
        }
        try {
            wifiLock?.let { if (it.isHeld) it.release() }
        } catch (_: Exception) {
        }
    }
}
