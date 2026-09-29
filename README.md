# «Тихий Омут» — Still Waters

A small, playable Godot 4 pixel-fishing prototype built around the MVP in the concept brief. The project uses a 320×180 virtual canvas, nearest-neighbour rendering, procedural pixel scenery, and no external assets.

## Run

Open this folder in Godot 4.2+ and run `Main.tscn` (or press **F6** after opening the project). The game saves to `user://still_waters_save.json`.

## Controls

- **Enter / Space** — start from the title screen (Enter continues a save; N starts fresh)
- **Space** — cast, hook during the bite window; hold to reel and release to ease line tension
- **← / →** — choose bait
- **J** — fishing journal · **I** — tackle inventory · **M** — dockside shop
- Shop: **1** buy bait, **2** upgrade rod, **Enter** sell the catch
- **E** — sleep until morning · **Esc** — pause / close panels
- Pause: **S** save, **Q** return to title

## Prototype loop

Fish at the Old Pond, react to the bobber, manage line tension while reeling, fill the journal, sell catches, purchase bait and improve the rod. Time advances while playing; rain changes daily, improves bite speed, and unlocks the Golden Carp. The Phantom Eel appears only in rainy late-night hours. Progress is saved automatically after catches, purchases, sleeping, and day rollover.
