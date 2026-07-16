"""Generate reproducible legacy launcher PNGs from the Tabler Run geometry."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
CANVAS_SIZE = 1024
BLUE = (35, 91, 131, 255)
WHITE = (255, 255, 255, 255)
SCALE = 34.0
ORIGIN_X = (CANVAS_SIZE / 2) - (11.0 * SCALE)
ORIGIN_Y = (CANVAS_SIZE / 2) - (12.0 * SCALE)
STROKE_WIDTH = round(2.2 * SCALE)


def point(x: float, y: float) -> tuple[float, float]:
    return ORIGIN_X + (x * SCALE), ORIGIN_Y + (y * SCALE)


def rounded_polyline(draw: ImageDraw.ImageDraw, coordinates: list[tuple[float, float]]) -> None:
    points = [point(x, y) for x, y in coordinates]
    draw.line(points, fill=WHITE, width=STROKE_WIDTH, joint="curve")
    radius = STROKE_WIDTH / 2
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=WHITE)


def create_icon(round_background: bool) -> Image.Image:
    image = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    if round_background:
        draw.ellipse((32, 32, 992, 992), fill=BLUE)
    else:
        draw.rounded_rectangle((32, 32, 992, 992), radius=224, fill=BLUE)

    head_x, head_y = point(13.007, 5)
    head_radius = 2 * SCALE
    draw.ellipse(
        (
            head_x - head_radius,
            head_y - head_radius,
            head_x + head_radius,
            head_y + head_radius,
        ),
        outline=WHITE,
        width=STROKE_WIDTH,
    )
    rounded_polyline(draw, [(4, 17), (9, 18), (9.75, 16.5)])
    rounded_polyline(draw, [(15, 21), (15, 17), (11, 14), (12, 8)])
    rounded_polyline(draw, [(7, 12), (7, 9), (12, 8), (15, 11), (18, 12)])
    return image


def main() -> None:
    square = create_icon(round_background=False)
    round_icon = create_icon(round_background=True)

    branding_dir = ROOT / "assets" / "branding"
    branding_dir.mkdir(parents=True, exist_ok=True)
    square.save(branding_dir / "run_walk_timer_icon.png", optimize=True)

    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for directory, size in sizes.items():
        output_dir = ROOT / "android" / "app" / "src" / "main" / "res" / directory
        output_dir.mkdir(parents=True, exist_ok=True)
        square.resize((size, size), Image.Resampling.LANCZOS).save(
            output_dir / "ic_launcher.png", optimize=True
        )
        round_icon.resize((size, size), Image.Resampling.LANCZOS).save(
            output_dir / "ic_launcher_round.png", optimize=True
        )


if __name__ == "__main__":
    main()
