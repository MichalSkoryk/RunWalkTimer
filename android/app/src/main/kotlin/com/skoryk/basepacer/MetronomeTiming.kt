package com.skoryk.basepacer

/** Pure timing helpers that avoid accumulating rounded per-beat intervals. */
object MetronomeTiming {
    const val MIN_BPM = 70
    const val MAX_BPM = 180
    const val DEFAULT_WALK_BPM = 100
    const val DEFAULT_RUN_BPM = 160

    fun sanitizeBpm(value: Int, fallback: Int): Int =
        if (value in MIN_BPM..MAX_BPM) value else fallback

    fun initialBeatIndex(immediate: Boolean): Long = if (immediate) 0L else 1L

    fun beatOffsetMs(beatIndex: Long, bpm: Int): Long {
        require(beatIndex >= 0L)
        require(bpm in MIN_BPM..MAX_BPM)
        return (beatIndex * 60_000L + bpm / 2L) / bpm
    }
}
