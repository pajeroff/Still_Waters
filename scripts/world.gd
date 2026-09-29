extends Node2D

const GRID_SIZE := Vector2i(30, 24)
const TILE_SIZE := Vector2i(32, 16)
const GRASS_A := Vector2i(0, 0)
const GRASS_B := Vector2i(1, 0)
const WATER_TILE := Vector2i(2, 0)
const DOCK_TILE := Vector2i(3, 0)
const PLAYER_START := Vector2i(15, 15)
const COLLISION_WORLD := 1 << 1
const COLLISION_WATER := 1 << 2
const COLLISION_INTERACTABLE := 1 << 4

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
	status_label.text = "WASD / стрелки — ходить   Shift — бежать   E — взаимодействие   Колесо — зум"

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
			var ground_atlas := GRASS_A if (x * 7 + y * 3) % 5 else GRASS_B
			ground_layer.set_cell(cell, 0, ground_atlas)
			if _is_water_cell(cell):
				water_layer.set_cell(cell, 0, WATER_TILE)
			if _is_dock_cell(cell):
				dock_layer.set_cell(cell, 0, DOCK_TILE)
	# A little path leads from the spawn to the wooden bank.
	for cell in [Vector2i(15, 14), Vector2i(14, 13), Vector2i(13, 12), Vector2i(12, 11)]:
		ground_layer.set_cell(cell, 0, Vector2i(4, 0))

func _is_water_cell(cell: Vector2i) -> bool:
	return cell.x >= 7 and cell.x <= 14 and cell.y >= 5 and cell.y <= 9 and not _is_dock_cell(cell)

func _is_dock_cell(cell: Vector2i) -> bool:
	return (cell.y == 10 and cell.x >= 8 and cell.x <= 13) or (cell.y == 11 and cell.x >= 10 and cell.x <= 12)

func _build_water_collision() -> void:
	for x in range(7, 15):
		for y in range(5, 10):
			var cell := Vector2i(x, y)
			if _is_dock_cell(cell):
				continue
			var body := StaticBody2D.new()
			body.name = "WaterCollision_%02d_%02d" % [x, y]
			body.collision_layer = COLLISION_WATER
			body.collision_mask = 0
			var polygon := CollisionPolygon2D.new()
			polygon.polygon = PackedVector2Array([Vector2(0, -7.5), Vector2(15.5, 0), Vector2(0, 7.5), Vector2(-15.5, 0)])
			body.add_child(polygon)
			sort_root.add_child(body)
			body.position = ground_layer.map_to_local(cell)

func _build_obstacles() -> void:
	_spawn_obstacle("Oak_A", "res://assets/oak.png", Vector2i(5, 7), Vector2(0, -29), Vector2(7, 11))
	_spawn_obstacle("Oak_B", "res://assets/oak.png", Vector2i(21, 16), Vector2(0, -29), Vector2(7, 11))
	_spawn_obstacle("Oak_C", "res://assets/oak.png", Vector2i(24, 7), Vector2(0, -29), Vector2(7, 11))
	_spawn_obstacle("Rock_A", "res://assets/rock.png", Vector2i(6, 16), Vector2(0, -7), Vector2(8, 6))
	_spawn_obstacle("Rock_B", "res://assets/rock.png", Vector2i(19, 9), Vector2(0, -7), Vector2(8, 6))
	_spawn_obstacle("Old_Stump", "res://assets/stump.png", Vector2i(18, 18), Vector2(0, -10), Vector2(7, 5))

func _spawn_obstacle(object_name: String, texture_path: String, cell: Vector2i, sprite_offset: Vector2, collider_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = object_name
	body.collision_layer = COLLISION_WORLD
	body.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path) as Texture2D
	sprite.position = sprite_offset
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = collider_size.x
	shape.height = maxf(collider_size.y * 2.0, collider_size.x * 2.0)
	collision.shape = shape
	collision.position = Vector2(0, -collider_size.y * 0.5)
	body.add_child(collision)
	sort_root.add_child(body)
	body.position = ground_layer.map_to_local(cell)

func _build_boundaries() -> void:
	_add_wall("Boundary_North", Vector2(48, -31), Vector2(960, 24))
	_add_wall("Boundary_South", Vector2(48, 431), Vector2(960, 24))
	_add_wall("Boundary_West", Vector2(-393, 200), Vector2(24, 500))
	_add_wall("Boundary_East", Vector2(489, 200), Vector2(24, 500))

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
	_add_interactable("OldPondFishingSpot", "Точка ловли", "У воды тихо. Рыбалка подключится следующим этапом.", Vector2i(10, 10))
	_add_interactable("OldOak", "Старый дуб", "Под ветвями пахнет дождём и влажной корой.", Vector2i(5, 7))

func _add_interactable(point_name: String, title: String, description: String, cell: Vector2i) -> void:
	var point := InteractablePoint.new()
	point.name = point_name
	point.display_name = title
	point.response = description
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
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
