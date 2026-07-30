package com.skoryk.base.pacer

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.SoundPool
import android.os.Handler
import android.os.Looper

/** Plays selectable workout cues and metronome ticks on independent streams. */
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
        .setMaxStreams(2)
        .setAudioAttributes(audioAttributes)
        .build()
    private val soundIds = mutableMapOf<String, Int>()
    private val loadedSoundIds = mutableSetOf<Int>()

    private var pendingCue: String? = null
    private var pendingMetronome: String? = null
    private var cueStreamId = 0
    private var metronomeStreamId = 0
    private var released = false
    private val releaseCueFocus = Runnable {
        cueStreamId = 0
        audioManager.abandonAudioFocusRequest(focusRequest)
    }

    init {
        soundPool.setOnLoadCompleteListener { _, sampleId, status ->
            if (released || status != 0) {
                return@setOnLoadCompleteListener
            }
            loadedSoundIds.add(sampleId)
            pendingCue?.let { key ->
                if (soundIds[key] == sampleId) {
                    pendingCue = null
                    playLoadedCue(key, sampleId)
                }
            }
            pendingMetronome?.let { key ->
                if (soundIds[key] == sampleId) {
                    pendingMetronome = null
                    playLoadedMetronome(sampleId)
                }
            }
        }

        load(context, key(CUE_WALK, "classic"), R.raw.workout_cue_walk)
        load(context, key(CUE_WALK, "soft_bell"), R.raw.workout_cue_walk_soft_bell)
        load(context, key(CUE_WALK, "wood_tone"), R.raw.workout_cue_walk_wood_tone)
        load(context, key(CUE_RUN, "classic"), R.raw.workout_cue_run)
        load(context, key(CUE_RUN, "bright_bell"), R.raw.workout_cue_run_bright_bell)
        load(context, key(CUE_RUN, "digital_double"), R.raw.workout_cue_run_digital_double)
        load(context, key(CUE_COMPLETE, "classic"), R.raw.workout_cue_complete)
        load(
            context,
            key(CUE_COMPLETE, "success_chime"),
            R.raw.workout_cue_complete_success_chime,
        )
        load(
            context,
            key(CUE_COMPLETE, "bell_finish"),
            R.raw.workout_cue_complete_bell_finish,
        )
        load(
            context,
            key(CUE_METRONOME, "sharp_click"),
            R.raw.workout_metronome_sharp_click,
        )
        load(
            context,
            key(CUE_METRONOME, "wood_tick"),
            R.raw.workout_metronome_wood_tick,
        )
        load(
            context,
            key(CUE_METRONOME, "digital_tick"),
            R.raw.workout_metronome_digital_tick,
        )
    }

    fun playCue(cue: String?, soundId: String?) {
        val cueName = cue ?: return
        val selected = when (cueName) {
            CUE_WALK -> SoundSettingsStore.sanitizeWalk(soundId)
            CUE_RUN -> SoundSettingsStore.sanitizeRun(soundId)
            CUE_COMPLETE -> SoundSettingsStore.sanitizeCompletion(soundId)
            else -> return
        }
        val soundKey = key(cueName, selected)
        val sampleId = soundIds[soundKey] ?: return
        stopCue()
        audioManager.requestAudioFocus(focusRequest)
        if (loadedSoundIds.contains(sampleId)) {
            playLoadedCue(soundKey, sampleId)
        } else {
            pendingCue = soundKey
        }
    }

    fun playMetronome(soundId: String?) {
        val soundKey = key(
            CUE_METRONOME,
            SoundSettingsStore.sanitizeMetronome(soundId),
        )
        val sampleId = soundIds[soundKey] ?: return
        if (loadedSoundIds.contains(sampleId)) {
            playLoadedMetronome(sampleId)
        } else {
            pendingMetronome = soundKey
        }
    }

    fun preview(category: String?, soundId: String?) {
        when (category) {
            CUE_METRONOME -> playMetronome(soundId)
            CUE_WALK, CUE_RUN, CUE_COMPLETE -> playCue(category, soundId)
        }
    }

    fun stopCue() {
        handler.removeCallbacks(releaseCueFocus)
        pendingCue = null
        if (cueStreamId != 0) {
            soundPool.stop(cueStreamId)
            cueStreamId = 0
        }
        audioManager.abandonAudioFocusRequest(focusRequest)
    }

    fun stopMetronome() {
        pendingMetronome = null
        if (metronomeStreamId != 0) {
            soundPool.stop(metronomeStreamId)
            metronomeStreamId = 0
        }
    }

    fun stop() {
        stopCue()
        stopMetronome()
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

    private fun load(context: Context, soundKey: String, resourceId: Int) {
        soundIds[soundKey] = soundPool.load(context, resourceId, 1)
    }

    private fun playLoadedCue(soundKey: String, sampleId: Int) {
        if (released) {
            return
        }
        cueStreamId = soundPool.play(sampleId, 1f, 1f, 1, 0, 1f)
        handler.removeCallbacks(releaseCueFocus)
        handler.postDelayed(
            releaseCueFocus,
            durationFor(soundKey) + AUDIO_FOCUS_RELEASE_PADDING_MS,
        )
    }

    private fun playLoadedMetronome(sampleId: Int) {
        if (released) {
            return
        }
        if (metronomeStreamId != 0) {
            soundPool.stop(metronomeStreamId)
        }
        metronomeStreamId = soundPool.play(sampleId, 1f, 1f, 1, 0, 1f)
    }

    private fun durationFor(soundKey: String): Long = when {
        soundKey.startsWith("$CUE_WALK:") -> WALK_DURATION_MS
        soundKey.startsWith("$CUE_RUN:") -> RUN_DURATION_MS
        soundKey.startsWith("$CUE_COMPLETE:") -> COMPLETION_DURATION_MS
        else -> 0L
    }

    companion object {
        const val CUE_WALK = "walk"
        const val CUE_RUN = "run"
        const val CUE_COMPLETE = "complete"
        const val CUE_METRONOME = "metronome"
        const val COMPLETION_DURATION_MS = 880L

        private const val WALK_DURATION_MS = 420L
        private const val RUN_DURATION_MS = 570L
        private const val AUDIO_FOCUS_RELEASE_PADDING_MS = 120L

        private fun key(category: String, soundId: String): String = "$category:$soundId"
    }
}
