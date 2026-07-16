package com.intervalrunner.run_walk_timer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.drawable.Icon
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import kotlin.math.max
import kotlin.math.min

class WorkoutTimerService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val cueHandler = Handler(Looper.getMainLooper())
    private lateinit var notificationManager: NotificationManager
    private var toneGenerator: ToneGenerator? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private var status = STATUS_IDLE
    private var walkMs = 0L
    private var runMs = 0L
    private var targetMs = 0L
    private var limitMode = LIMIT_INTERVALS
    private var intervalCount = 1
    private var soundEnabled = true
    private var accumulatedMs = 0L
    private var runningAnchorMs = 0L
    private var runningAnchorWallMs = 0L
    private var checkpointElapsedMs = 0L
    private var sessionId = 0L
    private var lastSegmentOrdinal = 0L
    private var bootCount = -1
    private var lastRenderedSecond = -1L
    private var lastRenderedOrdinal = -1L

    private val tick = object : Runnable {
        override fun run() {
            if (status != STATUS_RUNNING) {
                return
            }
            reconcileAndRender()
            if (status == STATUS_RUNNING) {
                handler.postDelayed(this, TICK_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        serviceAlive = true
        notificationManager = getSystemService(NotificationManager::class.java)
        toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 85)
        createNotificationChannel()
        loadState()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startNewSession(intent)
            ACTION_PAUSE -> {
                if (matchesSession(intent)) {
                    pauseSession()
                }
            }
            ACTION_RESUME -> {
                if (matchesSession(intent)) {
                    resumeSession()
                }
            }
            ACTION_STOP -> {
                if (matchesSession(intent)) {
                    stopSession()
                }
            }
            ACTION_SET_SOUND -> setSound(intent.getBooleanExtra(EXTRA_SOUND, true))
            else -> restoreSession()
        }

        return if (status == STATUS_RUNNING || status == STATUS_PAUSED) {
            START_STICKY
        } else {
            START_NOT_STICKY
        }
    }

    private fun startNewSession(intent: Intent) {
        handler.removeCallbacksAndMessages(null)
        cueHandler.removeCallbacksAndMessages(null)
        toneGenerator?.stopTone()

        walkMs = intent.getLongExtra(EXTRA_WALK_MS, 0L)
        runMs = intent.getLongExtra(EXTRA_RUN_MS, 0L)
        targetMs = intent.getLongExtra(EXTRA_TARGET_MS, 0L)
        if (walkMs <= 0L || runMs <= 0L || targetMs <= 0L) {
            stopSelf()
            return
        }

        limitMode = intent.getStringExtra(EXTRA_LIMIT_MODE) ?: LIMIT_INTERVALS
        intervalCount = max(1, intent.getIntExtra(EXTRA_INTERVAL_COUNT, 1))
        soundEnabled = intent.getBooleanExtra(EXTRA_SOUND, true)
        accumulatedMs = 0L
        runningAnchorMs = SystemClock.elapsedRealtime()
        runningAnchorWallMs = System.currentTimeMillis()
        checkpointElapsedMs = 0L
        sessionId = System.currentTimeMillis()
        lastSegmentOrdinal = 0L
        bootCount = currentBootCount(this)
        status = STATUS_RUNNING
        lastRenderedSecond = -1L
        lastRenderedOrdinal = -1L

        persistState()
        acquireWakeLock()
        ensureForeground(buildNotification(derive(0L)))
        emitState(0L)
        scheduleTick()
    }

    private fun restoreSession() {
        loadState()
        val currentBootCount = currentBootCount(this)
        if (status == STATUS_RUNNING && bootCount != currentBootCount) {
            status = STATUS_PAUSED
            accumulatedMs = checkpointElapsedMs.coerceIn(0L, targetMs)
            runningAnchorMs = 0L
            runningAnchorWallMs = 0L
        }
        if ((status == STATUS_RUNNING || status == STATUS_PAUSED) &&
            bootCount != currentBootCount
        ) {
            bootCount = currentBootCount
            persistState()
        }

        if (status == STATUS_RUNNING || status == STATUS_PAUSED) {
            val elapsed = currentElapsed()
            val derived = derive(elapsed)
            ensureForeground(buildNotification(derived))
            if (status == STATUS_RUNNING) {
                acquireWakeLock()
                scheduleTick()
            }
            emitState(elapsed)
        } else {
            stopSelf()
        }
    }

    private fun pauseSession() {
        if (status != STATUS_RUNNING) {
            return
        }

        reconcileAndRender()
        if (status != STATUS_RUNNING) {
            return
        }

        accumulatedMs = currentElapsed()
        runningAnchorMs = 0L
        runningAnchorWallMs = 0L
        checkpointElapsedMs = accumulatedMs
        status = STATUS_PAUSED
        handler.removeCallbacks(tick)
        releaseWakeLock()
        persistState()

        val derived = derive(accumulatedMs)
        updateNotification(buildNotification(derived))
        emitState(accumulatedMs)
    }

    private fun resumeSession() {
        if (status != STATUS_PAUSED) {
            return
        }

        runningAnchorMs = SystemClock.elapsedRealtime()
        runningAnchorWallMs = System.currentTimeMillis()
        bootCount = currentBootCount(this)
        status = STATUS_RUNNING
        lastRenderedSecond = -1L
        persistState()
        acquireWakeLock()

        val derived = derive(accumulatedMs)
        ensureForeground(buildNotification(derived))
        emitState(accumulatedMs)
        scheduleTick()
    }

    private fun stopSession() {
        if (status == STATUS_RUNNING) {
            reconcileAndRender()
        }
        if (status == STATUS_COMPLETE) {
            notificationManager.cancel(NOTIFICATION_ID)
        }

        status = STATUS_IDLE
        accumulatedMs = 0L
        runningAnchorMs = 0L
        runningAnchorWallMs = 0L
        checkpointElapsedMs = 0L
        handler.removeCallbacksAndMessages(null)
        cueHandler.removeCallbacksAndMessages(null)
        toneGenerator?.stopTone()
        releaseWakeLock()
        persistState()
        emitState(0L)
        stopForeground(STOP_FOREGROUND_REMOVE)
        notificationManager.cancel(NOTIFICATION_ID)
        stopSelf()
    }

    private fun setSound(enabled: Boolean) {
        soundEnabled = enabled
        if (!enabled) {
            cueHandler.removeCallbacksAndMessages(null)
            toneGenerator?.stopTone()
        }
        persistState()
        if (status == STATUS_RUNNING || status == STATUS_PAUSED) {
            updateNotification(buildNotification(derive(currentElapsed())))
            emitState(currentElapsed())
        }
    }

    private fun reconcileAndRender() {
        val elapsed = currentElapsed()
        if (elapsed >= targetMs) {
            completeSession()
            return
        }

        val derived = derive(elapsed)
        val phaseChanged = derived.segmentOrdinal != lastSegmentOrdinal
        if (phaseChanged) {
            lastSegmentOrdinal = derived.segmentOrdinal
            checkpointElapsedMs = elapsed
            persistState()
            playPhaseCue(derived.isWalking)
        } else if (elapsed - checkpointElapsedMs >= CHECKPOINT_INTERVAL_MS) {
            checkpointElapsedMs = elapsed
            persistCheckpoint()
        }

        val displayedSecond = ceilSeconds(derived.displayRemainingMs)
        if (displayedSecond != lastRenderedSecond ||
            derived.segmentOrdinal != lastRenderedOrdinal
        ) {
            lastRenderedSecond = displayedSecond
            lastRenderedOrdinal = derived.segmentOrdinal
            updateNotification(buildNotification(derived))
            emitState(elapsed)
        }
    }

    private fun completeSession() {
        if (status == STATUS_COMPLETE) {
            return
        }

        status = STATUS_COMPLETE
        accumulatedMs = targetMs
        runningAnchorMs = 0L
        runningAnchorWallMs = 0L
        checkpointElapsedMs = targetMs
        handler.removeCallbacksAndMessages(null)
        releaseWakeLock()
        persistState()
        playCompletionCue()

        val notification = buildCompletionNotification()
        stopForeground(STOP_FOREGROUND_DETACH)
        notificationManager.notify(NOTIFICATION_ID, notification)
        emitState(targetMs)
        if (soundEnabled) {
            cueHandler.postDelayed(
                { stopSelf() },
                COMPLETION_CUE_RELEASE_DELAY_MS,
            )
        } else {
            stopSelf()
        }
    }

    private fun currentElapsed(): Long {
        val elapsed = if (status == STATUS_RUNNING) {
            accumulatedMs + max(0L, SystemClock.elapsedRealtime() - runningAnchorMs)
        } else {
            accumulatedMs
        }
        return elapsed.coerceIn(0L, targetMs)
    }

    private fun derive(elapsed: Long): DerivedState {
        val cycleMs = walkMs + runMs
        val complete = elapsed >= targetMs
        val positionElapsed = if (complete) max(0L, targetMs - 1L) else elapsed
        val cycleIndex = positionElapsed / cycleMs
        val position = positionElapsed % cycleMs
        val isWalking = position < walkMs
        val phaseRemaining = if (isWalking) {
            walkMs - position
        } else {
            cycleMs - position
        }
        val totalRemaining = max(0L, targetMs - elapsed)
        val displayRemaining = if (complete) {
            0L
        } else {
            min(phaseRemaining, totalRemaining)
        }

        return DerivedState(
            isWalking = isWalking,
            displayRemainingMs = displayRemaining,
            totalRemainingMs = totalRemaining,
            cycleIndex = cycleIndex,
            segmentOrdinal = cycleIndex * 2L + if (isWalking) 0L else 1L,
        )
    }

    private fun buildNotification(state: DerivedState): Notification {
        val phase = if (state.isWalking) "Walking" else "Running"
        val interval = formatDuration(state.displayRemainingMs, false)
        val overall = formatDuration(state.totalRemainingMs, true)
        val content = "Interval " + interval + "  •  Overall " + overall
        val paused = status == STATUS_PAUSED

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_interval)
            .setColor(if (state.isWalking) Color.rgb(8, 127, 91) else Color.rgb(232, 89, 12))
            .setContentTitle(if (paused) "Workout paused • " + phase else phase)
            .setContentText(content)
            .setStyle(Notification.BigTextStyle().bigText(content))
            .setSubText(
                if (limitMode == LIMIT_INTERVALS) {
                    "Cycle " + (state.cycleIndex + 1L) + " of " + intervalCount
                } else {
                    "Timed workout"
                },
            )
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setContentIntent(openAppIntent())
            .setShowWhen(!paused)
            .setUsesChronometer(!paused)
            .setWhen(System.currentTimeMillis() + state.displayRemainingMs)
            .setChronometerCountDown(!paused)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }

        val primaryAction = if (paused) {
            notificationAction(
                R.drawable.ic_notification_play,
                "Resume",
                ACTION_RESUME,
                REQUEST_RESUME,
            )
        } else {
            notificationAction(
                R.drawable.ic_notification_pause,
                "Pause",
                ACTION_PAUSE,
                REQUEST_PAUSE,
            )
        }
        builder.addAction(primaryAction)
        builder.addAction(
            notificationAction(
                R.drawable.ic_notification_stop,
                "Stop",
                ACTION_STOP,
                REQUEST_STOP,
            ),
        )

        return builder.build()
    }

    private fun buildCompletionNotification(): Notification {
        val content = "Active time " + formatDuration(targetMs, true)
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_interval)
            .setColor(Color.rgb(35, 91, 131))
            .setContentTitle("Workout complete")
            .setContentText(content)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent())
            .build()
    }

    private fun notificationAction(
        iconResource: Int,
        title: String,
        action: String,
        requestCode: Int,
    ): Notification.Action {
        val icon = Icon.createWithResource(this, iconResource)
        return Notification.Action.Builder(
            icon,
            title,
            servicePendingIntent(action, requestCode),
        )
            .build()
    }

    private fun servicePendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, WorkoutTimerService::class.java).apply {
            this.action = action
            data = Uri.parse("runwalk://session/" + sessionId + "/" + action)
            putExtra(EXTRA_SESSION_ID, sessionId)
        }
        return PendingIntent.getService(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openAppIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this,
            REQUEST_OPEN,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun matchesSession(intent: Intent): Boolean {
        if (!intent.hasExtra(EXTRA_SESSION_ID)) {
            return true
        }
        return intent.getLongExtra(EXTRA_SESSION_ID, -1L) == sessionId
    }

    private fun ensureForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotification(notification: Notification) {
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active workout",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Current walk/run interval and workout controls"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun scheduleTick() {
        handler.removeCallbacks(tick)
        handler.postDelayed(tick, TICK_MS)
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            return
        }
        val powerManager = getSystemService(PowerManager::class.java)
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "run_walk_timer:active_workout",
        ).apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        wakeLock = null
    }

    private fun playPhaseCue(isWalking: Boolean) {
        if (soundEnabled) {
            if (isWalking) {
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 180)
            } else {
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP2, 120)
                cueHandler.postDelayed(
                    { toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP2, 120) },
                    190,
                )
            }
        }
        vibrate(if (isWalking) longArrayOf(0L, 100L) else longArrayOf(0L, 80L, 80L, 80L))
    }

    private fun playCompletionCue() {
        if (soundEnabled) {
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 150)
            cueHandler.postDelayed(
                { toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 150) },
                210,
            )
            cueHandler.postDelayed(
                { toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 240) },
                420,
            )
        }
        vibrate(longArrayOf(0L, 350L))
    }

    private fun vibrate(pattern: LongArray) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as Vibrator
        }
        vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
    }

    private fun emitState(elapsed: Long) {
        WorkoutServiceEvents.emit(stateMap(elapsed))
    }

    private fun stateMap(elapsed: Long): HashMap<String, Any?> {
        return hashMapOf(
            "status" to status,
            "walkMs" to walkMs,
            "runMs" to runMs,
            "targetMs" to targetMs,
            "limitMode" to limitMode,
            "intervalCount" to intervalCount,
            "elapsedMs" to elapsed,
            "soundEnabled" to soundEnabled,
            "sessionId" to sessionId,
            "notificationsEnabled" to notificationsEnabled(this),
        )
    }

    private fun persistState() {
        getSharedPreferences(PREFERENCES, MODE_PRIVATE)
            .edit()
            .putString(KEY_STATUS, status)
            .putLong(KEY_WALK_MS, walkMs)
            .putLong(KEY_RUN_MS, runMs)
            .putLong(KEY_TARGET_MS, targetMs)
            .putString(KEY_LIMIT_MODE, limitMode)
            .putInt(KEY_INTERVAL_COUNT, intervalCount)
            .putBoolean(KEY_SOUND, soundEnabled)
            .putLong(KEY_ACCUMULATED_MS, accumulatedMs)
            .putLong(KEY_RUNNING_ANCHOR_MS, runningAnchorMs)
            .putLong(KEY_RUNNING_ANCHOR_WALL_MS, runningAnchorWallMs)
            .putLong(KEY_CHECKPOINT_ELAPSED_MS, checkpointElapsedMs)
            .putLong(KEY_SESSION_ID, sessionId)
            .putLong(KEY_LAST_ORDINAL, lastSegmentOrdinal)
            .putInt(KEY_BOOT_COUNT, bootCount)
            .apply()
    }

    private fun persistCheckpoint() {
        getSharedPreferences(PREFERENCES, MODE_PRIVATE)
            .edit()
            .putLong(KEY_CHECKPOINT_ELAPSED_MS, checkpointElapsedMs)
            .apply()
    }

    private fun loadState() {
        val preferences = getSharedPreferences(PREFERENCES, MODE_PRIVATE)
        status = preferences.getString(KEY_STATUS, STATUS_IDLE) ?: STATUS_IDLE
        walkMs = preferences.getLong(KEY_WALK_MS, 0L)
        runMs = preferences.getLong(KEY_RUN_MS, 0L)
        targetMs = preferences.getLong(KEY_TARGET_MS, 0L)
        limitMode = preferences.getString(KEY_LIMIT_MODE, LIMIT_INTERVALS)
            ?: LIMIT_INTERVALS
        intervalCount = preferences.getInt(KEY_INTERVAL_COUNT, 1)
        soundEnabled = preferences.getBoolean(KEY_SOUND, true)
        accumulatedMs = preferences.getLong(KEY_ACCUMULATED_MS, 0L)
        runningAnchorMs = preferences.getLong(KEY_RUNNING_ANCHOR_MS, 0L)
        runningAnchorWallMs = preferences.getLong(KEY_RUNNING_ANCHOR_WALL_MS, 0L)
        checkpointElapsedMs = preferences.getLong(
            KEY_CHECKPOINT_ELAPSED_MS,
            accumulatedMs,
        )
        sessionId = preferences.getLong(KEY_SESSION_ID, 0L)
        lastSegmentOrdinal = preferences.getLong(KEY_LAST_ORDINAL, 0L)
        bootCount = preferences.getInt(KEY_BOOT_COUNT, -1)
    }

    override fun onDestroy() {
        serviceAlive = false
        handler.removeCallbacksAndMessages(null)
        cueHandler.removeCallbacksAndMessages(null)
        releaseWakeLock()
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    private data class DerivedState(
        val isWalking: Boolean,
        val displayRemainingMs: Long,
        val totalRemainingMs: Long,
        val cycleIndex: Long,
        val segmentOrdinal: Long,
    )

    companion object {
        const val ACTION_START = "com.intervalrunner.run_walk_timer.START"
        const val ACTION_PAUSE = "com.intervalrunner.run_walk_timer.PAUSE"
        const val ACTION_RESUME = "com.intervalrunner.run_walk_timer.RESUME"
        const val ACTION_STOP = "com.intervalrunner.run_walk_timer.STOP"
        const val ACTION_SET_SOUND = "com.intervalrunner.run_walk_timer.SET_SOUND"

        const val EXTRA_WALK_MS = "walkMs"
        const val EXTRA_RUN_MS = "runMs"
        const val EXTRA_TARGET_MS = "targetMs"
        const val EXTRA_LIMIT_MODE = "limitMode"
        const val EXTRA_INTERVAL_COUNT = "intervalCount"
        const val EXTRA_SOUND = "soundEnabled"
        const val EXTRA_SESSION_ID = "sessionId"

        private const val STATUS_IDLE = "idle"
        private const val STATUS_RUNNING = "running"
        private const val STATUS_PAUSED = "paused"
        private const val STATUS_COMPLETE = "complete"
        private const val LIMIT_INTERVALS = "intervals"
        private const val PREFERENCES = "workout_timer_service"
        private const val KEY_STATUS = "status"
        private const val KEY_WALK_MS = "walk_ms"
        private const val KEY_RUN_MS = "run_ms"
        private const val KEY_TARGET_MS = "target_ms"
        private const val KEY_LIMIT_MODE = "limit_mode"
        private const val KEY_INTERVAL_COUNT = "interval_count"
        private const val KEY_SOUND = "sound"
        private const val KEY_ACCUMULATED_MS = "accumulated_ms"
        private const val KEY_RUNNING_ANCHOR_MS = "running_anchor_ms"
        private const val KEY_RUNNING_ANCHOR_WALL_MS = "running_anchor_wall_ms"
        private const val KEY_CHECKPOINT_ELAPSED_MS = "checkpoint_elapsed_ms"
        private const val KEY_SESSION_ID = "session_id"
        private const val KEY_LAST_ORDINAL = "last_ordinal"
        private const val KEY_BOOT_COUNT = "boot_count"
        private const val CHANNEL_ID = "active_workout"
        private const val NOTIFICATION_ID = 4101
        private const val REQUEST_OPEN = 4102
        private const val REQUEST_PAUSE = 4103
        private const val REQUEST_RESUME = 4104
        private const val REQUEST_STOP = 4105
        private const val TICK_MS = 250L
        private const val CHECKPOINT_INTERVAL_MS = 5_000L
        private const val COMPLETION_CUE_RELEASE_DELAY_MS = 750L

        @Volatile
        private var serviceAlive = false

        fun isAlive(): Boolean = serviceAlive

        fun currentState(context: Context): HashMap<String, Any?>? {
            val preferences = context.getSharedPreferences(PREFERENCES, MODE_PRIVATE)
            val walkMs = preferences.getLong(KEY_WALK_MS, 0L)
            val runMs = preferences.getLong(KEY_RUN_MS, 0L)
            val targetMs = preferences.getLong(KEY_TARGET_MS, 0L)
            if (walkMs <= 0L || runMs <= 0L || targetMs <= 0L) {
                return null
            }

            var status = preferences.getString(KEY_STATUS, STATUS_IDLE) ?: STATUS_IDLE
            var accumulated = preferences.getLong(KEY_ACCUMULATED_MS, 0L)
            val anchor = preferences.getLong(KEY_RUNNING_ANCHOR_MS, 0L)
            val anchorWall = preferences.getLong(KEY_RUNNING_ANCHOR_WALL_MS, 0L)
            val checkpoint = preferences.getLong(
                KEY_CHECKPOINT_ELAPSED_MS,
                accumulated,
            )
            val savedBootCount = preferences.getInt(KEY_BOOT_COUNT, -1)
            val currentBootCount = currentBootCount(context)
            val staleRunning = status == STATUS_RUNNING &&
                (!serviceAlive || savedBootCount != currentBootCount)

            if (staleRunning) {
                accumulated = interruptedElapsed(
                    context = context,
                    accumulated = accumulated,
                    checkpoint = checkpoint,
                    anchorWall = anchorWall,
                    targetMs = targetMs,
                )
                status = if (accumulated >= targetMs) {
                    STATUS_COMPLETE
                } else {
                    STATUS_PAUSED
                }
                preferences.edit()
                    .putString(KEY_STATUS, status)
                    .putLong(KEY_ACCUMULATED_MS, accumulated)
                    .putLong(KEY_RUNNING_ANCHOR_MS, 0L)
                    .putLong(KEY_RUNNING_ANCHOR_WALL_MS, 0L)
                    .putLong(KEY_CHECKPOINT_ELAPSED_MS, accumulated)
                    .putInt(KEY_BOOT_COUNT, currentBootCount)
                    .apply()
            } else if (status == STATUS_PAUSED &&
                savedBootCount != currentBootCount
            ) {
                preferences.edit()
                    .putInt(KEY_BOOT_COUNT, currentBootCount)
                    .apply()
            }

            val elapsed = if (status == STATUS_RUNNING) {
                accumulated + max(0L, SystemClock.elapsedRealtime() - anchor)
            } else {
                accumulated
            }.coerceIn(0L, targetMs)
            if (elapsed >= targetMs) {
                status = STATUS_COMPLETE
            }

            return hashMapOf(
                "status" to status,
                "walkMs" to walkMs,
                "runMs" to runMs,
                "targetMs" to targetMs,
                "limitMode" to (
                    preferences.getString(KEY_LIMIT_MODE, LIMIT_INTERVALS)
                        ?: LIMIT_INTERVALS
                ),
                "intervalCount" to preferences.getInt(KEY_INTERVAL_COUNT, 1),
                "elapsedMs" to elapsed,
                "soundEnabled" to preferences.getBoolean(KEY_SOUND, true),
                "sessionId" to preferences.getLong(KEY_SESSION_ID, 0L),
                "notificationsEnabled" to notificationsEnabled(context),
            )
        }

        private fun interruptedElapsed(
            context: Context,
            accumulated: Long,
            checkpoint: Long,
            anchorWall: Long,
            targetMs: Long,
        ): Long {
            var recovered = checkpoint
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && anchorWall > 0L) {
                try {
                    val activityManager = context.getSystemService(
                        ActivityManager::class.java,
                    )
                    val userStop = activityManager
                        .getHistoricalProcessExitReasons(context.packageName, 0, 10)
                        .firstOrNull { exit ->
                            exit.reason == ApplicationExitInfo.REASON_USER_REQUESTED &&
                                exit.timestamp >= anchorWall
                        }
                    if (userStop != null) {
                        recovered = max(
                            recovered,
                            accumulated + max(0L, userStop.timestamp - anchorWall),
                        )
                    }
                } catch (_: RuntimeException) {
                    // The recent persisted checkpoint remains a safe fallback.
                }
            }
            return recovered.coerceIn(0L, targetMs)
        }

        private fun notificationsEnabled(context: Context): Boolean {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (!manager.areNotificationsEnabled()) {
                return false
            }
            val channel = manager.getNotificationChannel(CHANNEL_ID)
            return channel == null || channel.importance != NotificationManager.IMPORTANCE_NONE
        }

        private fun currentBootCount(context: Context): Int {
            return Settings.Global.getInt(
                context.contentResolver,
                Settings.Global.BOOT_COUNT,
                -1,
            )
        }

        private fun ceilSeconds(milliseconds: Long): Long {
            if (milliseconds <= 0L) {
                return 0L
            }
            return (milliseconds + 999L) / 1000L
        }

        private fun formatDuration(milliseconds: Long, alwaysHours: Boolean): String {
            val totalSeconds = ceilSeconds(milliseconds)
            val hours = totalSeconds / 3600L
            val minutes = (totalSeconds % 3600L) / 60L
            val seconds = totalSeconds % 60L
            return if (alwaysHours || hours > 0L) {
                String.format("%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format("%02d:%02d", totalSeconds / 60L, seconds)
            }
        }
    }
}
