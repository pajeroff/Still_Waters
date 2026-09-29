extends Node2D

const WORLD_SIZE := Vector2(3200.0, 2400.0)
const LAKE_CENTER := Vector2(1870.0, 850.0)
const START_POINT := Vector2(1320.0, 1320.0)

const TREE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/tree_oak.png"),
	preload("res://assets/tree_pine.png"),
	preload("res://assets/tree_spruce.png"),
	preload("res://assets/tree_round.png"),
	preload("res://assets/tree_autumn.png"),
	preload("res://assets/tree_gold.png")
]
const BUSH_TEXTURES: Array[Texture2D] = [
	preload("res://assets/bush.png"),
	preload("res://assets/bush_dark.png"),
	preload("res://assets/bush_berry.png")
]
const FLOWER_TEXTURES: Array[Texture2D] = [
	preload("res://assets/flower_yellow.png"),
	preload("res://assets/flower_yellow2.png"),
	preload("res://assets/flower_red.png"),
	preload("res://assets/flower_white.png"),
	preload("res://assets/flower_purple.png")
]
const ROCK_TEXTURES: Array[Texture2D] = [
	preload("res://assets/rock_small.png"),
	preload("res://assets/rock_small2.png"),
	preload("res://assets/rock_small3.png"),
	preload("res://assets/rock_big.png")
]
const TUFT_TEXTURE: Texture2D = preload("res://assets/grass_tuft.png")
const LOG_TEXTURE: Texture2D = preload("res://assets/log.png")

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 615044
	_make_border_forest()
	_make_lakeside_trees()
	_make_scattered_trees()
	_make_ground_details()

func _make_border_forest() -> void:
	# Loose bands of trees frame the playable meadow like a natural vignette.
	for i in range(20):
		var x := 110.0 + float(i) * 157.0 + rng.randf_range(-32.0, 32.0)
		_add_tree(Vector2(x, rng.randf_range(105.0, 330.0)))
		_add_tree(Vector2(x + rng.randf_range(-52.0, 52.0), rng.randf_range(2100.0, 2320.0)))
	for i in range(13):
		var y := 400.0 + float(i) * 126.0 + rng.randf_range(-35.0, 35.0)
		_add_tree(Vector2(rng.randf_range(100.0, 340.0), y))
		_add_tree(Vector2(rng.randf_range(2860.0, 3110.0), y + rng.randf_range(-45.0, 45.0)))

func _make_lakeside_trees() -> void:
	for i in range(31):
		var angle := TAU * float(i) / 31.0 + rng.randf_range(-0.09, 0.09)
		var radius_x := rng.randf_range(1.22, 1.65)
		var radius_y := rng.randf_range(1.24, 1.65)
		var p := LAKE_CENTER + Vector2(cos(angle) * 455.0 * radius_x, sin(angle) * 300.0 * radius_y)
		if _near_path(p, 145.0):
			continue
		_add_tree(p)

func _make_scattered_trees() -> void:
	var placed := 0
	var attempts := 0
	while placed < 34 and attempts < 500:
		attempts += 1
		var p := Vector2(rng.randf_range(360.0, 2840.0), rng.randf_range(360.0, 2040.0))
		if p.distance_to(START_POINT) < 440.0:
			continue
		if _in_lake(p, 500.0, 340.0) or _near_path(p, 150.0):
			continue
		_add_tree(p)
		placed += 1

func _make_ground_details() -> void:
	# Tufts, flower pockets, stones and shrubs sit along the trail and shoreline.
	for i in range(64):
		var p := _random_land_point()
		_add_sprite(TUFT_TEXTURE, p, rng.randf_range(0.58, 0.90), rng.randf() < 0.5)

	for i in range(92):
		var p := _random_land_point()
		if _near_path(p, 26.0):
			continue
		var texture: Texture2D = FLOWER_TEXTURES[rng.randi_range(0, FLOWER_TEXTURES.size() - 1)]
		_add_sprite(texture, p, rng.randf_range(0.72, 1.05), rng.randf() < 0.5)

	for i in range(38):
		var p := _random_land_point()
		if p.distance_to(START_POINT) < 150.0 or _near_path(p, 70.0):
			continue
		var texture: Texture2D = BUSH_TEXTURES[rng.randi_range(0, BUSH_TEXTURES.size() - 1)]
		_add_sprite(texture, p, rng.randf_range(0.78, 1.08), rng.randf() < 0.5)

	for i in range(34):
		var p := _random_land_point()
		if _near_path(p, 48.0):
			continue
		var texture: Texture2D = ROCK_TEXTURES[rng.randi_range(0, ROCK_TEXTURES.size() - 1)]
		var size := rng.randf_range(0.74, 1.08) if texture.get_width() > 40 else rng.randf_range(0.95, 1.35)
		_add_sprite(texture, p, size, false)

	# One old branch beside the way, and a few tiny shrub clusters at the water.
	_add_sprite(LOG_TEXTURE, Vector2(1680, 1260), 0.92, true)
	_add_sprite(BUSH_TEXTURES[2], Vector2(2250, 1055), 0.90, false)
	_add_sprite(BUSH_TEXTURES[0], Vector2(1460, 880), 0.84, true)

func _random_land_point() -> Vector2:
	for attempt in range(80):
		var p := Vector2(rng.randf_range(80.0, WORLD_SIZE.x - 80.0), rng.randf_range(80.0, WORLD_SIZE.y - 80.0))
		if not _in_lake(p, 445.0, 292.0):
			return p
	return Vector2(900.0, 900.0)

func _add_tree(p: Vector2) -> void:
	var texture: Texture2D = TREE_TEXTURES[rng.randi_range(0, TREE_TEXTURES.size() - 1)]
	_add_sprite(texture, p, rng.randf_range(0.88, 1.06), false)

func _add_sprite(texture: Texture2D, p: Vector2, size: float, flip: bool) -> void:
	var anchor := Node2D.new()
	anchor.position = p
	anchor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(anchor)

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.flip_h = flip
	sprite.scale = Vector2.ONE * size
	sprite.position = Vector2(0, -float(texture.get_height()) * size * 0.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anchor.add_child(sprite)

func _in_lake(p: Vector2, rx: float, ry: float) -> bool:
	var q := (p - LAKE_CENTER) / Vector2(rx, ry)
	return q.length_squared() < 1.0

func _near_path(p: Vector2, radius: float) -> bool:
	var points := PackedVector2Array([
		Vector2(-40, 2360), Vector2(160, 2160), Vector2(385, 1980),
		Vector2(650, 1820), Vector2(900, 1690), Vector2(1110, 1530),
		Vector2(1280, 1370), Vector2(1450, 1190), Vector2(1580, 1080)
	])
	for i in range(points.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])
		if closest.distance_to(p) < radius:
			return true
	return false
