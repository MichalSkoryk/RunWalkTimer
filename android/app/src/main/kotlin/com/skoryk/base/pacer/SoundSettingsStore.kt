package com.skoryk.base.pacer

import android.content.Context

data class SoundSettingsSelection(
    val walkCue: String,
    val runCue: String,
    val completionCue: String,
    val metronome: String,
) {
    fun toMap(): HashMap<String, String> = hashMapOf(
        SoundSettingsStore.KEY_WALK_CUE to walkCue,
        SoundSettingsStore.KEY_RUN_CUE to runCue,
        SoundSettingsStore.KEY_COMPLETION_CUE to completionCue,
        SoundSettingsStore.KEY_METRONOME to metronome,
    )
}

object SoundSettingsStore {
    const val KEY_WALK_CUE = "walkCue"
    const val KEY_RUN_CUE = "runCue"
    const val KEY_COMPLETION_CUE = "completionCue"
    const val KEY_METRONOME = "metronome"

    const val DEFAULT_WALK_CUE = "classic"
    const val DEFAULT_RUN_CUE = "classic"
    const val DEFAULT_COMPLETION_CUE = "classic"
    const val DEFAULT_METRONOME = "sharp_click"

    private const val PREFERENCES = "sound_settings"
    private val walkSounds = setOf("classic", "soft_bell", "wood_tone")
    private val runSounds = setOf("classic", "bright_bell", "digital_double")
    private val completionSounds = setOf("classic", "success_chime", "bell_finish")
    private val metronomeSounds = setOf("sharp_click", "wood_tick", "digital_tick")

    fun load(context: Context): SoundSettingsSelection {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        return SoundSettingsSelection(
            walkCue = sanitizeWalk(preferences.getString(KEY_WALK_CUE, null)),
            runCue = sanitizeRun(preferences.getString(KEY_RUN_CUE, null)),
            completionCue = sanitizeCompletion(
                preferences.getString(KEY_COMPLETION_CUE, null),
            ),
            metronome = sanitizeMetronome(preferences.getString(KEY_METRONOME, null)),
        )
    }

    fun save(context: Context, raw: Map<*, *>): SoundSettingsSelection {
        val selection = SoundSettingsSelection(
            walkCue = sanitizeWalk(raw[KEY_WALK_CUE] as? String),
            runCue = sanitizeRun(raw[KEY_RUN_CUE] as? String),
            completionCue = sanitizeCompletion(raw[KEY_COMPLETION_CUE] as? String),
            metronome = sanitizeMetronome(raw[KEY_METRONOME] as? String),
        )
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_WALK_CUE, selection.walkCue)
            .putString(KEY_RUN_CUE, selection.runCue)
            .putString(KEY_COMPLETION_CUE, selection.completionCue)
            .putString(KEY_METRONOME, selection.metronome)
            .apply()
        return selection
    }

    fun sanitizeWalk(value: String?): String =
        if (value in walkSounds) value!! else DEFAULT_WALK_CUE

    fun sanitizeRun(value: String?): String =
        if (value in runSounds) value!! else DEFAULT_RUN_CUE

    fun sanitizeCompletion(value: String?): String =
        if (value in completionSounds) value!! else DEFAULT_COMPLETION_CUE

    fun sanitizeMetronome(value: String?): String =
        if (value in metronomeSounds) value!! else DEFAULT_METRONOME
}
