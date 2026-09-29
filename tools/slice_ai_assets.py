"""Extract transparent game sprites from the generated AI sprite atlases.

Requires Pillow. Source atlases live in assets/source; this script writes the
runtime-ready, tightly packed sprite sheet and prop PNGs into assets/.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source"
ASSETS = ROOT / "assets"
NEAREST = Image.Resampling.NEAREST


def remove_magenta_background(image: Image.Image) -> Image.Image:
    """Key the generated solid-magenta atlas background and its cast shadows."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _a = pixels[x, y]
            magenta_hue = r > g * 1.3 + 16 and b > g * 1.2 + 12 and abs(r - b) < 65
            if magenta_hue and r > 45 and b > 45:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def crop_visible(cell: Image.Image, padding: int = 2) -> Image.Image:
    alpha = cell.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(cell.width, right + padding)
    bottom = min(cell.height, bottom + padding)
    return cell.crop((left, top, right, bottom))


def make_angler_frames() -> None:
    atlas = Image.open(SOURCE / "angler_ai_sheet_magenta.png").convert("RGB")
    cell_w, cell_h = atlas.width // 8, atlas.height // 4
    facing_columns = {"E": 2, "SE": 3, "S": 4, "SW": 5, "W": 6, "NW": 7, "N": 0, "NE": 1}
    facings = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
    # Atlas rows: idle, walk-contact, walk-passing, walk-opposite-contact.
    animation_rows = [0, 1, 2, 3, 2]
    frame_w, frame_h = 24, 40
    output = Image.new("RGBA", (frame_w * len(animation_rows), frame_h * len(facings)), (0, 0, 0, 0))

    for row, facing in enumerate(facings):
        for column, atlas_row in enumerate(animation_rows):
            atlas_column = facing_columns[facing]
            cell = atlas.crop((atlas_column * cell_w + 5, atlas_row * cell_h + 5, (atlas_column + 1) * cell_w - 5, (atlas_row + 1) * cell_h - 5))
            sprite = crop_visible(remove_magenta_background(cell), padding=2)
            max_w, max_h = frame_w - 2, frame_h - 2
            scale = min(max_w / sprite.width, max_h / sprite.height)
            new_size = (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale)))
            sprite = sprite.resize(new_size, NEAREST)
            x = (frame_w - sprite.width) // 2
            y = frame_h - sprite.height
            output.alpha_composite(sprite, (column * frame_w + x, row * frame_h + y))
    output.save(ASSETS / "angler_sheet.png", optimize=True)


def make_vegetation_sprites() -> None:
    atlas = Image.open(SOURCE / "vegetation_sheet_magenta.png").convert("RGB")
    cell_w, cell_h = atlas.width // 4, atlas.height // 3
    names = [
        ["oak", "birch", "shrub", "bush"],
        ["reeds", "flowers", "boulder", "stump"],
        ["sign", "lantern", "lily_pads", "fern"],
    ]
    target_sizes = {
        "oak": (96, 116), "birch": (68, 116), "shrub": (82, 72), "bush": (64, 64),
        "reeds": (64, 92), "flowers": (72, 60), "boulder": (70, 52), "stump": (56, 52),
        "sign": (48, 76), "lantern": (48, 92), "lily_pads": (90, 58), "fern": (76, 60),
    }
    for row, row_names in enumerate(names):
        for column, name in enumerate(row_names):
            inset = 18
            cell = atlas.crop((column * cell_w + inset, row * cell_h + inset, (column + 1) * cell_w - inset, (row + 1) * cell_h - inset))
            sprite = crop_visible(remove_magenta_background(cell), padding=4)
            max_w, max_h = target_sizes[name]
            scale = min(max_w / sprite.width, max_h / sprite.height)
            new_size = (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale)))
            sprite = sprite.resize(new_size, NEAREST)
            canvas = Image.new("RGBA", (max_w, max_h), (0, 0, 0, 0))
            canvas.alpha_composite(sprite, ((max_w - sprite.width) // 2, max_h - sprite.height))
            canvas.save(ASSETS / f"{name}.png", optimize=True)


def make_backdrop() -> None:
    image = Image.open(SOURCE / "world_backdrop_original.png").convert("RGB")
    # Crop to the 896:480 world aspect and keep the generated pixel clusters crisp.
    target_ratio = 896 / 480
    crop_h = round(image.width / target_ratio)
    top = (image.height - crop_h) // 2
    image = image.crop((0, top, image.width, top + crop_h))
    image = image.resize((896, 480), NEAREST)
    image.save(ASSETS / "world_backdrop.png", optimize=True)


if __name__ == "__main__":
    make_angler_frames()
    make_vegetation_sprites()
    make_backdrop()
    print("Sliced AI-generated sprites into assets/.")
