"""Generate deterministic Google Play graphics from the Base Pacer artwork.

Requires Pillow. Run from the repository root:

    python play-store/tools/generate_graphics.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ICON = ROOT / "assets" / "branding" / "run_walk_timer_icon.png"
SOURCE_FEATURE = (
    ROOT / "play-store" / "source" / "feature-background-generated.png"
)
OUTPUT_DIR = ROOT / "play-store" / "assets"
PLAY_ICON = OUTPUT_DIR / "app-icon-512.png"
FEATURE_GRAPHIC = OUTPUT_DIR / "feature-graphic-1024x500.png"

BLUE = (35, 91, 131)
OFF_WHITE = (246, 249, 250)
TEAL = (70, 205, 165)


def _font(name: str, size: int) -> ImageFont.FreeTypeFont:
    candidates = (
        Path("C:/Windows/Fonts") / name,
        Path("/usr/share/fonts/truetype/dejavu") / name,
    )
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    raise FileNotFoundError(f"Could not find a usable font for {name}")


def _cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_width, target_height = size
    source_ratio = image.width / image.height
    target_ratio = target_width / target_height
    if source_ratio > target_ratio:
        crop_width = round(image.height * target_ratio)
        left = (image.width - crop_width) // 2
        image = image.crop((left, 0, left + crop_width, image.height))
    else:
        crop_height = round(image.width / target_ratio)
        top = (image.height - crop_height) // 2
        image = image.crop((0, top, image.width, top + crop_height))
    return image.resize(size, Image.Resampling.LANCZOS)


def build_play_icon() -> None:
    source = Image.open(SOURCE_ICON).convert("RGBA")
    # Filling the transparent rounded corners produces full-bleed square artwork;
    # Google Play applies the final device-specific mask and shadow itself.
    full_bleed = Image.new("RGBA", source.size, BLUE + (255,))
    full_bleed.alpha_composite(source)
    icon = full_bleed.resize((512, 512), Image.Resampling.LANCZOS)
    icon.save(PLAY_ICON, format="PNG", optimize=True)


def build_feature_graphic() -> None:
    background = _cover(Image.open(SOURCE_FEATURE).convert("RGB"), (1024, 500))
    canvas = background.convert("RGBA")

    # Quiet the left side so the title remains readable at small preview sizes.
    shade = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shade_pixels = shade.load()
    for x in range(canvas.width):
        progress = x / canvas.width
        alpha = round(112 * max(0.0, 1.0 - progress / 0.68))
        for y in range(canvas.height):
            shade_pixels[x, y] = (6, 22, 34, alpha)
    canvas = Image.alpha_composite(canvas, shade)

    draw = ImageDraw.Draw(canvas)
    label_font = _font("segoeuib.ttf", 20)
    title_font = _font("segoeuib.ttf", 70)
    subtitle_font = _font("segoeui.ttf", 28)

    icon_source = Image.open(SOURCE_ICON).convert("RGBA")
    icon = icon_source.resize((76, 76), Image.Resampling.LANCZOS)
    canvas.alpha_composite(icon, (64, 54))

    draw.text((158, 63), "RUN / WALK TIMER", font=label_font, fill=TEAL)
    draw.text((62, 153), "BASE PACER", font=title_font, fill=OFF_WHITE)
    draw.rounded_rectangle((63, 258, 410, 262), radius=2, fill=TEAL)
    draw.text((63, 290), "Walk. Run. Repeat.", font=subtitle_font, fill=OFF_WHITE)

    canvas.convert("RGB").save(FEATURE_GRAPHIC, format="PNG", optimize=True)


def validate() -> None:
    expected = {
        PLAY_ICON: ((512, 512), "RGBA", 1_000_000),
        FEATURE_GRAPHIC: ((1024, 500), "RGB", None),
    }
    for path, (size, mode, max_bytes) in expected.items():
        with Image.open(path) as image:
            if image.size != size:
                raise ValueError(f"{path.name}: expected {size}, got {image.size}")
            if image.mode != mode:
                raise ValueError(f"{path.name}: expected {mode}, got {image.mode}")
        if max_bytes is not None and path.stat().st_size > max_bytes:
            raise ValueError(f"{path.name}: exceeds {max_bytes:,} bytes")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    build_play_icon()
    build_feature_graphic()
    validate()
    for output in (PLAY_ICON, FEATURE_GRAPHIC):
        print(f"{output.relative_to(ROOT)} ({output.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
