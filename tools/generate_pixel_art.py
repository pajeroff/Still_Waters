"""Generate placeholder pixel assets for the Still Waters iso movement test."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets"
OUT.mkdir(exist_ok=True)
PALETTE = {
    "outline": (42, 47, 42, 255), "shadow": (38, 57, 51, 105),
    "skin": (226, 173, 127, 255), "skin_shadow": (174, 116, 84, 255),
    "hair": (73, 50, 43, 255), "cap": (123, 83, 55, 255), "cap_lit": (170, 119, 74, 255),
    "coat": (54, 105, 104, 255), "coat_lit": (91, 151, 137, 255),
    "coat_shadow": (39, 73, 77, 255), "pack": (146, 108, 63, 255),
    "pants": (74, 72, 76, 255), "pants_lit": (104, 92, 84, 255),
    "boot": (91, 58, 43, 255), "boot_lit": (137, 88, 57, 255),
    "eye": (36, 48, 44, 255),
}


def make_player_sheet() -> None:
    cell_w, cell_h = 24, 40
    sheet = Image.new("RGBA", (cell_w * 6, cell_h * 8), (0, 0, 0, 0))
    # Row order matches the eight screen-space facing directions.
    directions = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
    for row, direction in enumerate(directions):
        for frame in range(6):
            im = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
            d = ImageDraw.Draw(im)
            idle = frame in (0, 1)
            walk_frame = max(0, frame - 2)
            bob = (1 if frame == 1 else 0) if idle else (1 if walk_frame in (1, 3) else 0)
            d.ellipse((5, 35, 19, 39), fill=PALETTE["shadow"])

            # Gait: alternating feet and arms. The sprite origin is at its feet.
            stride = 0 if idle else (-2 if walk_frame in (0, 2) else 2)
            left_leg_y = 0 if idle else (1 if walk_frame in (0, 2) else -1)
            right_leg_y = 0 if idle else (-1 if walk_frame in (0, 2) else 1)
            d.rectangle((8 + stride, 26 + bob, 11 + stride, 34 + left_leg_y), fill=PALETTE["pants"])
            d.rectangle((13 - stride, 26 + bob, 16 - stride, 34 + right_leg_y), fill=PALETTE["pants_lit"])
            d.rectangle((7 + stride, 33 + left_leg_y, 12 + stride, 37 + left_leg_y), fill=PALETTE["boot"])
            d.rectangle((12 - stride, 33 + right_leg_y, 17 - stride, 37 + right_leg_y), fill=PALETTE["boot_lit"])

            # Compact backpack is visible from behind and in three-quarter views.
            if direction in ("N", "NW", "NE", "W"):
                d.rectangle((5, 17 + bob, 8, 25 + bob), fill=PALETTE["pack"])
                d.rectangle((6, 18 + bob, 7, 22 + bob), fill=PALETTE["cap_lit"])

            arm_swing = 0 if idle else (2 if walk_frame in (0, 2) else -2)
            d.rectangle((5, 18 + bob + arm_swing, 7, 27 + bob + arm_swing), fill=PALETTE["skin_shadow"])
            d.rectangle((16, 18 + bob - arm_swing, 18, 27 + bob - arm_swing), fill=PALETTE["skin"])
            d.rectangle((7, 15 + bob, 17, 27 + bob), fill=PALETTE["coat_shadow"])
            d.rectangle((8, 15 + bob, 16, 25 + bob), fill=PALETTE["coat"])
            d.rectangle((8, 16 + bob, 10, 20 + bob), fill=PALETTE["coat_lit"])
            d.rectangle((11, 24 + bob, 15, 25 + bob), fill=PALETTE["coat_lit"])

            # Head / cap silhouette, adjusted to hint at facing without mirrored art.
            head_left = 8 if direction not in ("E", "NE", "SE") else 9
            head_right = 15 if direction not in ("W", "NW", "SW") else 14
            d.rectangle((head_left, 6 + bob, head_right, 16 + bob), fill=PALETTE["skin"])
            d.rectangle((head_left, 12 + bob, head_right, 15 + bob), fill=PALETTE["skin_shadow"])
            d.rectangle((7, 5 + bob, 16, 9 + bob), fill=PALETTE["hair"])
            d.rectangle((8, 3 + bob, 15, 7 + bob), fill=PALETTE["cap"])
            d.rectangle((9, 3 + bob, 14, 4 + bob), fill=PALETTE["cap_lit"])
            d.rectangle((6, 7 + bob, 17, 8 + bob), fill=PALETTE["cap"])
            if direction in ("S", "SE", "SW"):
                d.point((10 if direction != "SW" else 13, 10 + bob), fill=PALETTE["eye"])
                if direction == "S":
                    d.point((13, 10 + bob), fill=PALETTE["eye"])
            elif direction in ("E", "NE"):
                d.point((15, 10 + bob), fill=PALETTE["eye"])
            elif direction in ("W", "NW"):
                d.point((8, 10 + bob), fill=PALETTE["eye"])
            # Tiny neckerchief gives a clear front-facing pixel detail.
            if direction in ("S", "SE", "SW"):
                d.rectangle((11, 16 + bob, 13, 18 + bob), fill=(213, 137, 91, 255))

            sheet.alpha_composite(im, (frame * cell_w, row * cell_h))
    sheet.save(OUT / "angler_sheet.png", optimize=True)


def make_tiles() -> None:
    tile_w, tile_h = 32, 16
    sheet = Image.new("RGBA", (tile_w * 5, tile_h), (0, 0, 0, 0))
    styles = [
        ((95, 139, 88, 255), (124, 163, 99, 255)),
        ((114, 148, 91, 255), (148, 174, 105, 255)),
        ((75, 127, 125, 255), (120, 170, 153, 255)),
        ((131, 97, 66, 255), (180, 139, 91, 255)),
        ((180, 155, 109, 255), (211, 185, 132, 255)),
    ]
    for idx, (base, accent) in enumerate(styles):
        tile = Image.new("RGBA", (tile_w, tile_h), (0, 0, 0, 0))
        d = ImageDraw.Draw(tile)
        diamond = [(16, 0), (31, 7), (16, 15), (0, 7)]
        d.polygon(diamond, fill=base)
        d.line(diamond + [diamond[0]], fill=(53, 81, 59, 255), width=1)
        if idx in (0, 1):
            for x, y in ((5, 7), (10, 9), (22, 4), (25, 10), (16, 12)):
                d.point((x, y), fill=accent)
            if idx == 1:
                d.line((5, 8, 7, 6), fill=(81, 111, 66, 255))
        elif idx == 2:
            d.line((7, 7, 11, 6), fill=accent, width=1)
            d.line((19, 9, 24, 8), fill=(55, 103, 111, 255), width=1)
            d.point((15, 4), fill=(164, 195, 163, 255))
        elif idx == 3:
            d.line((5, 6, 26, 6), fill=accent, width=1)
            d.line((8, 9, 23, 9), fill=(104, 75, 54, 255), width=1)
            d.line((11, 4, 11, 11), fill=(157, 120, 79, 255), width=1)
            d.line((21, 3, 21, 10), fill=(157, 120, 79, 255), width=1)
        else:
            d.point((8, 7), fill=(202, 184, 137, 255))
            d.point((23, 5), fill=(222, 202, 151, 255))
        sheet.alpha_composite(tile, (idx * tile_w, 0))
    sheet.save(OUT / "isometric_tiles.png", optimize=True)


def make_obstacles() -> None:
    tree = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(tree)
    d.ellipse((12, 56, 37, 62), fill=(35, 52, 45, 120))
    d.rectangle((21, 38, 28, 57), fill=(93, 61, 43, 255))
    d.rectangle((19, 44, 22, 54), fill=(145, 94, 56, 255))
    d.polygon([(4, 34), (8, 17), (15, 14), (16, 6), (25, 3), (33, 9), (41, 12), (45, 27), (40, 39), (34, 44), (12, 42)], fill=(54, 98, 66, 255))
    d.polygon([(7, 27), (11, 14), (19, 10), (25, 7), (36, 15), (39, 27), (31, 34), (15, 35)], fill=(81, 130, 76, 255))
    d.rectangle((16, 13, 20, 16), fill=(115, 153, 84, 255))
    d.rectangle((28, 17, 33, 20), fill=(108, 151, 83, 255))
    d.rectangle((10, 28, 14, 31), fill=(106, 146, 77, 255))
    d.rectangle((34, 31, 37, 34), fill=(43, 85, 61, 255))
    tree.save(OUT / "oak.png", optimize=True)

    rock = Image.new("RGBA", (28, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(rock)
    d.ellipse((3, 15, 25, 19), fill=(35, 52, 45, 105))
    d.polygon([(3, 15), (4, 10), (9, 4), (16, 2), (23, 7), (25, 15), (20, 17), (7, 17)], fill=(104, 112, 99, 255))
    d.polygon([(5, 11), (10, 5), (16, 4), (19, 9), (12, 12)], fill=(151, 155, 127, 255))
    d.line((6, 14, 21, 14), fill=(77, 88, 79, 255))
    rock.save(OUT / "rock.png", optimize=True)

    stump = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(stump)
    d.ellipse((2, 18, 22, 22), fill=(35, 52, 45, 100))
    d.rectangle((6, 9, 18, 18), fill=(112, 74, 48, 255))
    d.ellipse((5, 5, 19, 12), fill=(164, 117, 69, 255))
    d.ellipse((9, 7, 16, 10), fill=(116, 76, 47, 255))
    stump.save(OUT / "stump.png", optimize=True)


make_player_sheet()
make_tiles()
make_obstacles()
