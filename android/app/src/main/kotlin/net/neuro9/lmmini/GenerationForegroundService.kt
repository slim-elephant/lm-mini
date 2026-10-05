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

/// Keeps the app process alive during chat generation (on-device, LM Studio, or
/// cloud) and shows a silent (IMPORTANCE_LOW) ongoing notification with progress.
///
/// On Android, a foreground service alone only stops the *process* from being
/// killed — it does NOT keep the CPU or WiFi radio awake. On-device generation
/// keeps the CPU busy on its own, but an idle HTTP stream (LM Studio / cloud)
/// would otherwise be frozen and its TCP socket dropped once the screen sleeps.
/// To keep those streams alive we hold a PARTIAL_WAKE_LOCK (CPU) and a
/// high-perf WifiLock (radio) for the lifetime of the service.
class GenerationForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "lmmini_generation"
        const val NOTIFICATION_ID = 9001

        /// Hard cap on how long the CPU wake lock is held, as a safety net against
        /// leaks if the service is killed without ACTION_STOP. The Dart side
        /// normally releases it well before this via stopGeneration / finally.
        const val GENERATION_TIMEOUT_MS = 30L * 60L * 1000L

        const val ACTION_START = "net.neuro9.lmmini.generation.START"
        const val ACTION_UPDATE = "net.neuro9.lmmini.generation.UPDATE"
        const val ACTION_STOP = "net.neuro9.lmmini.generation.STOP"

        const val EXTRA_MODEL_NAME = "modelName"
        const val EXTRA_CHAT_TITLE = "chatTitle"
        const val EXTRA_STATUS_TEXT = "statusText"
        const val EXTRA_TOKEN_COUNT = "tokenCount"
        const val EXTRA_TOKENS_PER_SECOND = "tokensPerSecond"
        const val EXTRA_KIND = "kind"
        const val EXTRA_PROGRESS = "progress"

        fun start(context: Context, modelName: String, chatTitle: String, kind: String = "chat") {
            val intent = Intent(context, GenerationForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_MODEL_NAME, modelName)
                putExtra(EXTRA_CHAT_TITLE, chatTitle)
                putExtra(EXTRA_KIND, kind)
                putExtra(
                    EXTRA_STATUS_TEXT,
                    if (kind == "image") "Generating image…" else "Starting…",
                )
            }
            context.startForegroundService(intent)
        }

        fun update(
            context: Context,
            modelName: String,
            statusText: String,
            tokenCount: Int,
            tokensPerSecond: Double,
            kind: String = "chat",
            progress: Double = 0.0,
        ) {
            val intent = Intent(context, GenerationForegroundService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_MODEL_NAME, modelName)
                putExtra(EXTRA_STATUS_TEXT, statusText)
                putExtra(EXTRA_TOKEN_COUNT, tokenCount)
                putExtra(EXTRA_TOKENS_PER_SECOND, tokensPerSecond)
                putExtra(EXTRA_KIND, kind)
                putExtra(EXTRA_PROGRESS, progress)
            }
            context.startService(intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, GenerationForegroundService::class.java).apply {
                action = ACTION_STOP
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
                "AI generation",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows progress while the model generates a response"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private var modelName: String = "AI Model"
    private var statusText: String = "Generating…"
    private var tokenCount: Int = 0
    private var tokensPerSecond: Double = 0.0
    private var kind: String = "chat"
    private var progress: Double = 0.0

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                modelName = intent.getStringExtra(EXTRA_MODEL_NAME) ?: modelName
                statusText = intent.getStringExtra(EXTRA_STATUS_TEXT) ?: "Starting…"
                kind = intent.getStringExtra(EXTRA_KIND) ?: "chat"
                progress = 0.0
                tokenCount = 0
                tokensPerSecond = 0.0
                ensureChannel(this)
                promoteToForeground(buildNotification(ongoing = true))
                acquireLocks()
            }
            ACTION_UPDATE -> {
                modelName = intent.getStringExtra(EXTRA_MODEL_NAME) ?: modelName
                statusText = intent.getStringExtra(EXTRA_STATUS_TEXT) ?: statusText
                tokenCount = intent.getIntExtra(EXTRA_TOKEN_COUNT, tokenCount)
                tokensPerSecond = intent.getDoubleExtra(EXTRA_TOKENS_PER_SECOND, tokensPerSecond)
                kind = intent.getStringExtra(EXTRA_KIND) ?: kind
                if (intent.hasExtra(EXTRA_PROGRESS)) {
                    progress = intent.getDoubleExtra(EXTRA_PROGRESS, progress)
                }
                val manager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(NOTIFICATION_ID, buildNotification(ongoing = true))
            }
            ACTION_STOP -> {
                releaseLocks()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        // Safety net: never leak the locks if the service dies unexpectedly.
        releaseLocks()
        super.onDestroy()
    }

    /// Acquire a partial CPU wake lock + high-perf WiFi lock so backgrounded
    /// HTTP streams keep being serviced while the screen is off. Idempotent.
    private fun acquireLocks() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "lmmini:generation",
                ).apply { setReferenceCounted(false) }
            }
            wakeLock?.let { if (!it.isHeld) it.acquire(GENERATION_TIMEOUT_MS) }
        } catch (_: Exception) {
            // Best effort; generation still works, just less reliably backgrounded.
        }
        try {
            if (wifiLock == null) {
                val wifiManager = applicationContext
                    .getSystemService(Context.WIFI_SERVICE) as WifiManager
                val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    WifiManager.WIFI_MODE_FULL_LOW_LATENCY
                } else {
                    @Suppress("DEPRECATION")
                    WifiManager.WIFI_MODE_FULL_HIGH_PERF
                }
                wifiLock = wifiManager.createWifiLock(mode, "lmmini:generation").apply {
                    setReferenceCounted(false)
                }
            }
            wifiLock?.let { if (!it.isHeld) it.acquire() }
        } catch (_: Exception) {
            // Best effort.
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

    private fun buildNotification(ongoing: Boolean): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val isImage = kind == "image"
        val contentText = buildString {
            append(statusText)
            if (!isImage && tokenCount > 0) {
                append(" · ")
                append(tokenCount)
                append(" tokens")
                if (tokensPerSecond > 0) {
                    append(" · ")
                    append(String.format("%.1f t/s", tokensPerSecond))
                }
            }
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(modelName)
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(ongoing)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        if (isImage) {
            val pct = (progress * 100.0).toInt().coerceIn(0, 100)
            builder.setProgress(100, pct, progress < 0.05)
        }

        return builder.build()
    }
}
