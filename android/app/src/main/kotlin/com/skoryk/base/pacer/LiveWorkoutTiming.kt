package com.skoryk.base.pacer

/** Pure calculations shared by live workout commands and unit tests. */
object LiveWorkoutTiming {
    fun elapsedAfterSkip(
        elapsedMs: Long,
        phaseRemainingMs: Long,
        targetMs: Long,
    ): Long {
        if (targetMs <= 0L) return 0L
        val elapsed = elapsedMs.coerceIn(0L, targetMs)
        val remaining = phaseRemainingMs.coerceAtLeast(0L)
        return elapsed + minOf(remaining, targetMs - elapsed)
    }
}
