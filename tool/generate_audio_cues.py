"""Generate normalized mono WAV cues used by the Android SoundPool player."""

import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "android" / "app" / "src" / "main" / "res" / "raw"
SAMPLE_RATE = 44_100
PEAK = 0.88


def tone(frequency: float, duration_ms: int) -> list[float]:
    sample_count = round(SAMPLE_RATE * duration_ms / 1000)
    attack = max(1, round(SAMPLE_RATE * 0.012))
    release = max(1, round(SAMPLE_RATE * 0.045))
    samples: list[float] = []
    for index in range(sample_count):
        envelope = min(1.0, index / attack, (sample_count - index - 1) / release)
        phase = 2 * math.pi * frequency * index / SAMPLE_RATE
        value = (math.sin(phase) + 0.16 * math.sin(phase * 2)) / 1.16
        samples.append(PEAK * max(0.0, envelope) * value)
    return samples


def silence(duration_ms: int) -> list[float]:
    return [0.0] * round(SAMPLE_RATE * duration_ms / 1000)


def write_wav(name: str, samples: list[float]) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / name
    frames = b"".join(
        struct.pack("<h", round(max(-1.0, min(1.0, sample)) * 32767))
        for sample in samples
    )
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(frames)


def main() -> None:
    write_wav("workout_cue_walk.wav", tone(660.0, 420))
    write_wav(
        "workout_cue_run.wav",
        tone(980.0, 220) + silence(130) + tone(980.0, 220),
    )
    write_wav(
        "workout_cue_complete.wav",
        tone(523.25, 200)
        + silence(90)
        + tone(659.25, 200)
        + silence(90)
        + tone(783.99, 300),
    )


if __name__ == "__main__":
    main()
