"""Frame privacy-safe device captures for the Google Play phone listing.

The raw captures intentionally contain only Base Pacer screens. This script
crops the device status/navigation bars, adds consistent listing copy, and
writes 1080 x 1920 RGB PNGs.

Run from the repository root after capturing the three source screens:

    python play-store/tools/generate_phone_screenshots.py
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "play-store" / "raw"
OUTPUT_DIR = ROOT / "play-store" / "assets" / "phone"
CANVAS_SIZE = (1080, 1920)
SCREEN_SIZE = (820, 1640)


@dataclass(frozen=True)
class ScreenshotSpec:
    source: str
    output: str
    title: str
    subtitle: str
    background: tuple[int, int, int]
    foreground: tuple[int, int, int]
    accent: tuple[int, int, int]


SPECS = (
    ScreenshotSpec(
        source="run-enabled.png",
        output="01-workout-setup-1080x1920.png",
        title="Set your plan",
        subtitle="Walk and run intervals with independent BPM.",
        background=(238, 246, 243),
        foreground=(16, 33, 44),
        accent=(8, 127, 91),
    ),
    ScreenshotSpec(
        source="02-active-run-final.png",
        output="02-active-workout-1080x1920.png",
        title="Follow every interval",
        subtitle="Current phase, total time, Skip and live BPM.",
        background=(16, 33, 44),
        foreground=(246, 249, 250),
        accent=(232, 89, 12),
    ),
    ScreenshotSpec(
        source="04-sound-settings.png",
        output="03-sound-settings-1080x1920.png",
        title="Make every cue yours",
        subtitle="Built-in walk, run, finish and metronome sounds.",
        background=(226, 239, 248),
        foreground=(16, 33, 44),
        accent=(35, 91, 131),
    ),
)


def _font(name: str, size: int) -> ImageFont.FreeTypeFont:
    candidates = (
        Path("C:/Windows/Fonts") / name,
        Path("/usr/share/fonts/truetype/dejavu") / name,
    )
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    raise FileNotFoundError(f"Could not find a usable font for {name}")


def _prepare_screen(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGB")
    if source.size != (1080, 2400):
        raise ValueError(f"{path.name}: expected 1080 x 2400, got {source.size}")
    # Remove the system status bar and three-button navigation bar. The crop is
    # still the real Flutter UI and preserves its original 1:2 aspect ratio.
    app_only = source.crop((0, 100, 1080, 2260))
    return app_only.resize(SCREEN_SIZE, Image.Resampling.LANCZOS)


def _rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, image.width - 1, image.height - 1),
        radius=radius,
        fill=255,
    )
    result = image.convert("RGBA")
    result.putalpha(mask)
    return result


def build(spec: ScreenshotSpec) -> Path:
    canvas = Image.new("RGB", CANVAS_SIZE, spec.background)
    draw = ImageDraw.Draw(canvas)
    title_font = _font("segoeuib.ttf", 62)
    subtitle_font = _font("segoeui.ttf", 28)

    draw.rounded_rectangle((72, 54, 88, 166), radius=8, fill=spec.accent)
    draw.text((116, 48), spec.title, font=title_font, fill=spec.foreground)
    draw.text((116, 132), spec.subtitle, font=subtitle_font, fill=spec.foreground)

    shadow = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((110, 230, 970, 1910), radius=58, fill=(0, 0, 0, 86))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    frame = Image.new("RGBA", (860, 1680), (248, 250, 252, 255))
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle(
        (0, 0, frame.width - 1, frame.height - 1),
        radius=58,
        outline=(255, 255, 255, 150),
        width=3,
    )
    screen = _rounded(_prepare_screen(RAW_DIR / spec.source), radius=42)
    frame.alpha_composite(screen, (20, 20))
    canvas.alpha_composite(frame, (110, 230))

    output = OUTPUT_DIR / spec.output
    canvas.convert("RGB").save(output, format="PNG", optimize=True)
    return output


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    outputs = [build(spec) for spec in SPECS]
    for output in outputs:
        with Image.open(output) as image:
            if image.size != CANVAS_SIZE or image.mode != "RGB":
                raise ValueError(
                    f"{output.name}: expected {CANVAS_SIZE} RGB, "
                    f"got {image.size} {image.mode}"
                )
        print(f"{output.relative_to(ROOT)} ({output.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
