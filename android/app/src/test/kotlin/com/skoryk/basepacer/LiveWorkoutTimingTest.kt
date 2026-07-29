package com.skoryk.basepacer

import org.junit.Assert.assertEquals
import org.junit.Test

class LiveWorkoutTimingTest {
    @Test
    fun `skip adds the remaining phase time to elapsed`() {
        assertEquals(
            140_000L,
            LiveWorkoutTiming.elapsedAfterSkip(
                elapsedMs = 100_000L,
                phaseRemainingMs = 40_000L,
                targetMs = 600_000L,
            ),
        )
    }

    @Test
    fun `skip cannot pass the workout target`() {
        assertEquals(
            120_000L,
            LiveWorkoutTiming.elapsedAfterSkip(
                elapsedMs = 100_000L,
                phaseRemainingMs = 40_000L,
                targetMs = 120_000L,
            ),
        )
    }

    @Test
    fun `live BPM change waits one full new beat`() {
        val firstBeat = MetronomeTiming.initialBeatIndex(immediate = false)
        assertEquals(600L, MetronomeTiming.beatOffsetMs(firstBeat, 100))
        assertEquals(333L, MetronomeTiming.beatOffsetMs(firstBeat, 180))
    }
}
