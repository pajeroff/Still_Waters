extends Node2D

const GRID_SIZE := Vector2i(30, 28)
const TILE_SIZE := Vector2i(32, 16)
const GRASS_A := Vector2i(0, 0)
const GRASS_B := Vector2i(1, 0)
const WATER_TILE := Vector2i(2, 0)
const DOCK_TILE := Vector2i(3, 0)
const PLAYER_START := Vector2i(15, 15)
const COLLISION_WORLD := 1 << 1
const COLLISION_WATER := 1 << 2

@onready var ground_layer: TileMapLayer = $YSort/Ground
@onready var water_layer: TileMapLayer = $YSort/Water
@onready var dock_layer: TileMapLayer = $YSort/Boardwalk
@onready var sort_root: Node2D = $YSort
@onready var player: CharacterBody2D = $YSort/Player
@onready var prompt_label: Label = $HUD/InteractionPrompt
@onready var status_label: Label = $HUD/Status

func _ready() -> void:
	var shared_tileset := _create_iso_tileset()
	ground_layer.tile_set = shared_tileset
	water_layer.tile_set = shared_tileset
	dock_layer.tile_set = shared_tileset
	_build_test_map()
	_build_water_collision()
	_build_obstacles()
	_build_boundaries()
	_build_interaction_points()
	player.position = ground_layer.map_to_local(PLAYER_START)
	player.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	player.interacted.connect(_on_player_interacted)
	player.moved_first_time.connect(_on_player_first_move)
	prompt_label.text = ""
	status_label.text = "WASD / стрелки — ходить     Shift — бег     E — действие"

func _create_iso_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = TILE_SIZE
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/isometric_tiles.png") as Texture2D
	atlas.texture_region_size = TILE_SIZE
	for tile_x in range(5):
		atlas.create_tile(Vector2i(tile_x, 0))
	tileset.add_source(atlas, 0)
	return tileset

func _build_test_map() -> void:
	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var cell := Vector2i(x, y)
			var ground_atlas: Vector2i = GRASS_A if (x * 7 + y * 3) % 5 else GRASS_B
			ground_layer.set_cell(cell, 0, ground_atlas)
			if _is_water_cell(cell):
				water_layer.set_cell(cell, 0, WATER_TILE)
			if _is_dock_cell(cell):
				dock_layer.set_cell(cell, 0, DOCK_TILE)

func _is_water_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x <= 12 and cell.y >= 15 and cell.y < GRID_SIZE.y and not _is_dock_cell(cell)

func _is_dock_cell(cell: Vector2i) -> bool:
	return cell.x >= 14 and cell.x <= 16 and cell.y >= 8 and cell.y <= 27

func _build_water_collision() -> void:
	for x in range(13):
		for y in range(15, GRID_SIZE.y):
			var cell := Vector2i(x, y)
			if not _is_water_cell(cell):
				continue
			var body := StaticBody2D.new()
			body.name = "WaterCollision_%02d_%02d" % [x, y]
			body.collision_layer = COLLISION_WATER
			body.collision_mask = 0
			var polygon := CollisionPolygon2D.new()
			polygon.polygon = PackedVector2Array([Vector2(0, -8), Vector2(16, 0), Vector2(0, 8), Vector2(-16, 0)])
			body.add_child(polygon)
			sort_root.add_child(body)
			body.position = ground_layer.map_to_local(cell)

func _build_obstacles() -> void:
	# Tree canopies and their trunk-sized collision shapes share the Y-sort anchor.
	_spawn_obstacle("Oak_01", "res://assets/oak.png", Vector2i(27, 3), 1.0, 9.0, 22.0)
	_spawn_obstacle("Oak_02", "res://assets/oak.png", Vector2i(23, 2), 1.0, 9.0, 22.0)
	_spawn_obstacle("Oak_03", "res://assets/oak.png", Vector2i(20, 0), 0.95, 9.0, 22.0)
	_spawn_obstacle("Oak_04", "res://assets/oak.png", Vector2i(5, 2), 0.9, 8.0, 20.0)
	_spawn_obstacle("Oak_05", "res://assets/oak.png", Vector2i(2, 8), 0.9, 8.0, 20.0)
	_spawn_obstacle("Oak_06", "res://assets/oak.png", Vector2i(27, 12), 1.0, 9.0, 22.0)
	_spawn_obstacle("Oak_07", "res://assets/oak.png", Vector2i(29, 18), 0.95, 9.0, 22.0)
	_spawn_obstacle("Oak_08", "res://assets/oak.png", Vector2i(17, 6), 0.9, 8.0, 20.0)
	_spawn_obstacle("Oak_09", "res://assets/oak.png", Vector2i(22, 10), 0.92, 8.0, 20.0)
	_spawn_obstacle("Oak_10", "res://assets/oak.png", Vector2i(25, 15), 0.95, 9.0, 22.0)
	_spawn_obstacle("Oak_11", "res://assets/oak.png", Vector2i(8, 3), 0.85, 8.0, 18.0)
	_spawn_obstacle("Birch_01", "res://assets/birch.png", Vector2i(17, 1), 1.0, 7.0, 18.0)
	_spawn_obstacle("Birch_02", "res://assets/birch.png", Vector2i(28, 7), 1.0, 7.0, 18.0)
	_spawn_obstacle("Birch_03", "res://assets/birch.png", Vector2i(23, 20), 0.95, 7.0, 18.0)
	_spawn_obstacle("Birch_04", "res://assets/birch.png", Vector2i(10, 3), 0.9, 7.0, 18.0)
	_spawn_obstacle("Birch_05", "res://assets/birch.png", Vector2i(27, 18), 0.92, 7.0, 18.0)
	_spawn_obstacle("Rock_01", "res://assets/boulder.png", Vector2i(8, 11), 0.85, 10.0, 16.0)
	_spawn_obstacle("Rock_02", "res://assets/boulder.png", Vector2i(24, 10), 0.8, 10.0, 16.0)
	_spawn_obstacle("Shrub_01", "res://assets/shrub.png", Vector2i(25, 4), 0.95, 9.0, 15.0)
	_spawn_obstacle("Shrub_02", "res://assets/shrub.png", Vector2i(21, 5), 0.9, 8.0, 14.0)
	_spawn_obstacle("Shrub_03", "res://assets/bush.png", Vector2i(29, 10), 0.85, 8.0, 14.0)
	_spawn_obstacle("Shrub_04", "res://assets/bush.png", Vector2i(19, 4), 0.9, 8.0, 14.0)
	_spawn_obstacle("Shrub_05", "res://assets/shrub.png", Vector2i(18, 10), 0.82, 8.0, 14.0)
	_spawn_obstacle("Shrub_06", "res://assets/bush.png", Vector2i(24, 15), 0.85, 8.0, 14.0)
	_spawn_obstacle("Shrub_07", "res://assets/bush.png", Vector2i(10, 2), 0.82, 8.0, 14.0)
	_spawn_obstacle("Stump_01", "res://assets/stump.png", Vector2i(19, 17), 0.9, 7.0, 13.0)

	# Ground details, bank vegetation and small set-dressing are also generated sprites.
	_spawn_decoration("Flowers_01", "res://assets/flowers.png", Vector2i(22, 2), 0.9)
	_spawn_decoration("Flowers_02", "res://assets/flowers.png", Vector2i(28, 5), 0.8)
	_spawn_decoration("Flowers_03", "res://assets/flowers.png", Vector2i(18, 3), 0.85)
	_spawn_decoration("Flowers_04", "res://assets/flowers.png", Vector2i(26, 9), 0.78)
	_spawn_decoration("Flowers_05", "res://assets/flowers.png", Vector2i(17, 7), 0.82)
	_spawn_decoration("Fern_01", "res://assets/fern.png", Vector2i(24, 7), 0.85)
	_spawn_decoration("Fern_02", "res://assets/fern.png", Vector2i(5, 8), 0.8)
	_spawn_decoration("Fern_03", "res://assets/fern.png", Vector2i(29, 14), 0.9)
	_spawn_decoration("Reeds_01", "res://assets/reeds.png", Vector2i(1, 18), 0.95)
	_spawn_decoration("Reeds_02", "res://assets/reeds.png", Vector2i(5, 21), 0.85)
	_spawn_decoration("Reeds_03", "res://assets/reeds.png", Vector2i(10, 25), 0.9)
	_spawn_decoration("LilyPads", "res://assets/lily_pads.png", Vector2i(3, 23), 0.9)
	_spawn_decoration("Lantern", "res://assets/lantern.png", Vector2i(18, 9), 0.85)
	_spawn_decoration("FishingSign", "res://assets/sign.png", Vector2i(14, 14), 0.85)

func _spawn_obstacle(object_name: String, texture_path: String, cell: Vector2i, sprite_scale: float, radius: float, collider_height: float) -> void:
	var body := StaticBody2D.new()
	body.name = object_name
	body.collision_layer = COLLISION_WORLD
	body.collision_mask = 0
	var sprite := Sprite2D.new()
	var texture := load(texture_path) as Texture2D
	sprite.texture = texture
	sprite.position = Vector2(0.0, -texture.get_height() * sprite_scale * 0.5)
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = radius
	shape.height = maxf(collider_height, radius * 2.0)
	collision.shape = shape
	collision.position = Vector2(0.0, -collider_height * 0.45)
	body.add_child(collision)
	sort_root.add_child(body)
	body.position = ground_layer.map_to_local(cell)

func _spawn_decoration(object_name: String, texture_path: String, cell: Vector2i, sprite_scale: float) -> void:
	var anchor := Node2D.new()
	anchor.name = object_name
	sort_root.add_child(anchor)
	anchor.position = ground_layer.map_to_local(cell)
	var sprite := Sprite2D.new()
	var texture := load(texture_path) as Texture2D
	sprite.texture = texture
	sprite.position = Vector2(0.0, -texture.get_height() * sprite_scale * 0.5)
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anchor.add_child(sprite)

func _build_boundaries() -> void:
	_add_wall("Boundary_North", Vector2(16, -25), Vector2(960, 24))
	_add_wall("Boundary_South", Vector2(16, 461), Vector2(960, 24))
	_add_wall("Boundary_West", Vector2(-444, 218), Vector2(24, 520))
	_add_wall("Boundary_East", Vector2(476, 218), Vector2(24, 520))

func _add_wall(wall_name: String, wall_position: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = wall_name
	body.collision_layer = COLLISION_WORLD
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	collision.shape = shape
	body.add_child(collision)
	sort_root.add_child(body)
	body.position = wall_position

func _build_interaction_points() -> void:
	_add_interactable("OldPondFishingSpot", "Ловить рыбу", "У воды тихо. Скоро здесь начнётся рыбалка.", Vector2i(15, 14))
	_add_interactable("OldOak", "Старый дуб", "Под ветвями пахнет дождём и влажной корой.", Vector2i(27, 3))

func _add_interactable(point_name: String, title: String, description: String, cell: Vector2i) -> void:
	var point := InteractablePoint.new()
	point.name = point_name
	point.display_name = title
	point.response = description
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	collision.shape = shape
	point.add_child(collision)
	point.activated.connect(_on_interactable_activated)
	sort_root.add_child(point)
	point.position = ground_layer.map_to_local(cell)

func _on_interaction_prompt_changed(prompt: String) -> void:
	prompt_label.text = prompt
	prompt_label.visible = not prompt.is_empty()

func _on_player_interacted(_target: InteractablePoint) -> void:
	pass

func _on_interactable_activated(point: InteractablePoint, _actor: Node2D) -> void:
	status_label.text = point.response

func _on_player_first_move() -> void:
	status_label.text = "Первый шаг сделан. Исследуй берега Старого пруда."
