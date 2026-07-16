package com.intervalrunner.run_walk_timer

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.SoundPool
import android.os.Handler
import android.os.Looper

/** Plays normalized workout cues and briefly ducks competing media audio. */
class WorkoutCuePlayer(context: Context) {
    private val handler = Handler(Looper.getMainLooper())
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val audioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()
    private val focusRequest = AudioFocusRequest.Builder(
        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
    )
        .setAudioAttributes(audioAttributes)
        .setOnAudioFocusChangeListener { }
        .build()
    private val soundPool = SoundPool.Builder()
        .setMaxStreams(1)
        .setAudioAttributes(audioAttributes)
        .build()
    private val soundIds = mutableMapOf<String, Int>()
    private val loadedSoundIds = mutableSetOf<Int>()

    private var pendingCue: String? = null
    private var currentStreamId = 0
    private var released = false

    init {
        soundPool.setOnLoadCompleteListener { _, sampleId, status ->
            if (released || status != 0) {
                return@setOnLoadCompleteListener
            }

            loadedSoundIds.add(sampleId)
            val cue = pendingCue
            if (cue != null && soundIds[cue] == sampleId) {
                pendingCue = null
                playLoadedCue(cue, sampleId)
            }
        }
        soundIds[CUE_WALK] = soundPool.load(context, R.raw.workout_cue_walk, 1)
        soundIds[CUE_RUN] = soundPool.load(context, R.raw.workout_cue_run, 1)
        soundIds[CUE_COMPLETE] = soundPool.load(
            context,
            R.raw.workout_cue_complete,
            1,
        )
    }

    fun play(cue: String?) {
        val cueName = cue ?: return
        val soundId = soundIds[cueName] ?: return
        stop()
        audioManager.requestAudioFocus(focusRequest)

        if (loadedSoundIds.contains(soundId)) {
            playLoadedCue(cueName, soundId)
        } else {
            pendingCue = cueName
        }
    }

    fun stop() {
        handler.removeCallbacksAndMessages(null)
        pendingCue = null
        if (currentStreamId != 0) {
            soundPool.stop(currentStreamId)
            currentStreamId = 0
        }
        audioManager.abandonAudioFocusRequest(focusRequest)
    }

    fun release() {
        if (released) {
            return
        }
        stop()
        released = true
        soundPool.setOnLoadCompleteListener(null)
        soundPool.release()
    }

    private fun playLoadedCue(cue: String, soundId: Int) {
        if (released) {
            return
        }
        currentStreamId = soundPool.play(soundId, 1f, 1f, 1, 0, 1f)
        handler.postDelayed(
            {
                currentStreamId = 0
                audioManager.abandonAudioFocusRequest(focusRequest)
            },
            durationFor(cue) + AUDIO_FOCUS_RELEASE_PADDING_MS,
        )
    }

    private fun durationFor(cue: String): Long = when (cue) {
        CUE_WALK -> WALK_DURATION_MS
        CUE_RUN -> RUN_DURATION_MS
        CUE_COMPLETE -> COMPLETION_DURATION_MS
        else -> 0L
    }

    companion object {
        const val CUE_WALK = "walk"
        const val CUE_RUN = "run"
        const val CUE_COMPLETE = "complete"
        const val COMPLETION_DURATION_MS = 880L

        private const val WALK_DURATION_MS = 420L
        private const val RUN_DURATION_MS = 570L
        private const val AUDIO_FOCUS_RELEASE_PADDING_MS = 120L
    }
}
