package com.intervalrunner.run_walk_timer

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var toneGenerator: ToneGenerator? = null
    private var deviceChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 85)

        deviceChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CHANNEL,
        )
        WorkoutServiceEvents.listener = { state ->
            runOnUiThread {
                deviceChannel?.invokeMethod("workoutServiceStateChanged", state)
            }
        }

        deviceChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "playCue" -> {
                    playCue(call.argument<String>("cue"))
                    result.success(null)
                }
                "setKeepScreenOn" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setKeepScreenOn(enabled)
                    result.success(null)
                }
                "startWorkoutService" -> {
                    try {
                        requestNotificationPermissionIfNeeded()
                        val intent = Intent(this, WorkoutTimerService::class.java).apply {
                            action = WorkoutTimerService.ACTION_START
                            putExtra(
                                WorkoutTimerService.EXTRA_WALK_MS,
                                (call.argument<Any>("walkMs") as Number).toLong(),
                            )
                            putExtra(
                                WorkoutTimerService.EXTRA_RUN_MS,
                                (call.argument<Any>("runMs") as Number).toLong(),
                            )
                            putExtra(
                                WorkoutTimerService.EXTRA_TARGET_MS,
                                (call.argument<Any>("targetMs") as Number).toLong(),
                            )
                            putExtra(
                                WorkoutTimerService.EXTRA_LIMIT_MODE,
                                call.argument<String>("limitMode"),
                            )
                            putExtra(
                                WorkoutTimerService.EXTRA_INTERVAL_COUNT,
                                (call.argument<Any?>("intervalCount") as? Number)
                                    ?.toInt() ?: 1,
                            )
                            putExtra(
                                WorkoutTimerService.EXTRA_SOUND,
                                call.argument<Boolean>("soundEnabled") ?: true,
                            )
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (error: Throwable) {
                        result.error(
                            "foreground_service_start_failed",
                            error.message,
                            null,
                        )
                    }
                }
                "pauseWorkoutService" -> {
                    sendWorkoutCommand(WorkoutTimerService.ACTION_PAUSE)
                    result.success(null)
                }
                "resumeWorkoutService" -> {
                    sendWorkoutCommand(WorkoutTimerService.ACTION_RESUME)
                    result.success(null)
                }
                "stopWorkoutService" -> {
                    sendWorkoutCommand(WorkoutTimerService.ACTION_STOP)
                    result.success(null)
                }
                "setWorkoutServiceSound" -> {
                    val intent = Intent(this, WorkoutTimerService::class.java).apply {
                        action = WorkoutTimerService.ACTION_SET_SOUND
                        putExtra(
                            WorkoutTimerService.EXTRA_SOUND,
                            call.argument<Boolean>("enabled") ?: true,
                        )
                    }
                    startService(intent)
                    result.success(null)
                }
                "getWorkoutServiceState" -> {
                    val state = WorkoutTimerService.currentState(this)
                    restoreWorkoutServiceIfNeeded(state)
                    result.success(state)
                }
                "openNotificationSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        },
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendWorkoutCommand(actionName: String) {
        val intent = Intent(this, WorkoutTimerService::class.java).apply {
            action = actionName
        }
        if (actionName == WorkoutTimerService.ACTION_RESUME &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
        ) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun restoreWorkoutServiceIfNeeded(state: HashMap<String, Any?>?) {
        if (state == null || WorkoutTimerService.isAlive()) {
            return
        }
        val status = state["status"] as? String
        if (status != "running" && status != "paused") {
            return
        }

        val intent = Intent(this, WorkoutTimerService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST,
            )
        }
    }

    private fun playCue(cue: String?) {
        handler.removeCallbacksAndMessages(null)
        when (cue) {
            "walk" -> toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 180)
            "run" -> {
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP2, 120)
                handler.postDelayed(
                    {
                        toneGenerator?.startTone(
                            ToneGenerator.TONE_PROP_BEEP2,
                            120,
                        )
                    },
                    190,
                )
            }
            "complete" -> {
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 150)
                handler.postDelayed(
                    {
                        toneGenerator?.startTone(
                            ToneGenerator.TONE_PROP_ACK,
                            150,
                        )
                    },
                    210,
                )
                handler.postDelayed(
                    {
                        toneGenerator?.startTone(
                            ToneGenerator.TONE_PROP_ACK,
                            240,
                        )
                    },
                    420,
                )
            }
        }
    }

    private fun setKeepScreenOn(enabled: Boolean) {
        if (enabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        WorkoutServiceEvents.listener = null
        deviceChannel?.setMethodCallHandler(null)
        deviceChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        private const val DEVICE_CHANNEL = "run_walk_timer/device"
        private const val NOTIFICATION_PERMISSION_REQUEST = 5101
    }
}
