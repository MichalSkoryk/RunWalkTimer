package com.skoryk.basepacer

import org.junit.Assert.assertEquals
import org.junit.Test

class MetronomeTimingTest {
    @Test
    fun `70 BPM has no accumulated drift after one minute`() {
        assertEquals(60_000L, MetronomeTiming.beatOffsetMs(70L, 70))
    }

    @Test
    fun `180 BPM has no accumulated drift after one minute`() {
        assertEquals(60_000L, MetronomeTiming.beatOffsetMs(180L, 180))
    }

    @Test
    fun `start and resume use an immediate beat`() {
        val firstBeat = MetronomeTiming.initialBeatIndex(immediate = true)
        assertEquals(0L, MetronomeTiming.beatOffsetMs(firstBeat, 100))
    }

    @Test
    fun `phase cue can act as downbeat before the first metronome tick`() {
        val firstBeat = MetronomeTiming.initialBeatIndex(immediate = false)
        assertEquals(375L, MetronomeTiming.beatOffsetMs(firstBeat, 160))
    }

    @Test
    fun `invalid restored BPM uses the phase fallback`() {
        assertEquals(100, MetronomeTiming.sanitizeBpm(69, 100))
        assertEquals(160, MetronomeTiming.sanitizeBpm(181, 160))
        assertEquals(70, MetronomeTiming.sanitizeBpm(70, 100))
        assertEquals(180, MetronomeTiming.sanitizeBpm(180, 160))
    }
}
