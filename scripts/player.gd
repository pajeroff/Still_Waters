extends CharacterBody2D

signal interacted(target: InteractablePoint)
signal interaction_prompt_changed(prompt: String)
signal moved_first_time

const SCREEN_DIRECTIONS := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
const SPRITE_CELL := Vector2i(24, 40)
const PLAYER_LAYER := 1
const WORLD_LAYER := 2
const WATER_LAYER := 4
const NPC_LAYER := 8
const INTERACTABLE_LAYER := 16

@export var walk_speed := 118.0
@export var run_multiplier := 1.55
@export var acceleration := 900.0
@export var braking := 1150.0

var facing := "S"
var nearby_points: Array[InteractablePoint] = []
var has_moved := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	collision_layer = PLAYER_LAYER
	collision_mask = WORLD_LAYER | WATER_LAYER | NPC_LAYER
	_ensure_input_map()
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.play("idle_S")
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)
	var input_strength := minf(input_vector.length(), 1.0)
	var iso_direction := Vector2(input_vector.x - input_vector.y, (input_vector.x + input_vector.y) * 0.5)
	if iso_direction.length_squared() > 0.0001:
		iso_direction = iso_direction.normalized()
		_update_facing(iso_direction)
	var speed_scale := run_multiplier if Input.is_action_pressed("run") else 1.0
	var target_velocity := iso_direction * walk_speed * speed_scale * input_strength
	var rate := acceleration if target_velocity.length_squared() > velocity.length_squared() else braking
	velocity = velocity.move_toward(target_velocity, rate * delta)
	move_and_slide()

	if velocity.length_squared() > 2.0:
		if not has_moved:
			has_moved = true
			moved_first_time.emit()
		animated_sprite.play("walk_%s" % facing)
	else:
		animated_sprite.play("idle_%s" % facing)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_interact_with_nearest()

func _update_facing(direction: Vector2) -> void:
	var angle := direction.angle()
	var direction_index := posmod(roundi(angle / (PI / 4.0)), SCREEN_DIRECTIONS.size())
	facing = str(SCREEN_DIRECTIONS[direction_index])

func _interact_with_nearest() -> void:
	_prune_invalid_interactables()
	if nearby_points.is_empty():
		return
	var target: InteractablePoint = nearby_points[0]
	var nearest_distance := global_position.distance_squared_to(target.global_position)
	for point in nearby_points:
		var distance := global_position.distance_squared_to(point.global_position)
		if distance < nearest_distance:
			target = point
			nearest_distance = distance
	target.interact(self)
	interacted.emit(target)

func _on_interaction_area_entered(area: Area2D) -> void:
	if area is InteractablePoint and not nearby_points.has(area):
		nearby_points.append(area)
		_update_interaction_prompt()

func _on_interaction_area_exited(area: Area2D) -> void:
	if area is InteractablePoint:
		nearby_points.erase(area)
		_update_interaction_prompt()

func _prune_invalid_interactables() -> void:
	for index in range(nearby_points.size() - 1, -1, -1):
		if not is_instance_valid(nearby_points[index]):
			nearby_points.remove_at(index)

func _update_interaction_prompt() -> void:
	_prune_invalid_interactables()
	var prompt := ""
	if not nearby_points.is_empty():
		prompt = "E  ·  %s" % nearby_points[0].display_name
	interaction_prompt_changed.emit(prompt)

func _build_sprite_frames() -> SpriteFrames:
	var sheet := load("res://assets/angler_sheet.png") as Texture2D
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for row in range(SCREEN_DIRECTIONS.size()):
		var direction: String = SCREEN_DIRECTIONS[row]
		var idle_name := "idle_%s" % direction
		frames.add_animation(idle_name)
		frames.set_animation_speed(idle_name, 2.0)
		frames.set_animation_loop(idle_name, true)
		frames.add_frame(idle_name, _atlas_frame(sheet, 0, row))
		frames.add_frame(idle_name, _atlas_frame(sheet, 1, row))

		var walk_name := "walk_%s" % direction
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, 9.0)
		frames.set_animation_loop(walk_name, true)
		for frame_index in range(1, 5):
			frames.add_frame(walk_name, _atlas_frame(sheet, frame_index + 1, row))
	return frames

func _atlas_frame(sheet: Texture2D, column: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(column * SPRITE_CELL.x, row * SPRITE_CELL.y, SPRITE_CELL.x, SPRITE_CELL.y)
	return frame

func _ensure_input_map() -> void:
	_ensure_action("move_up", [KEY_W, KEY_UP], -1, JOY_AXIS_LEFT_Y, -1.0)
	_ensure_action("move_down", [KEY_S, KEY_DOWN], -1, JOY_AXIS_LEFT_Y, 1.0)
	_ensure_action("move_left", [KEY_A, KEY_LEFT], -1, JOY_AXIS_LEFT_X, -1.0)
	_ensure_action("move_right", [KEY_D, KEY_RIGHT], -1, JOY_AXIS_LEFT_X, 1.0)
	_ensure_action("run", [KEY_SHIFT], JOY_BUTTON_LEFT_STICK)
	_ensure_action("interact", [KEY_E], JOY_BUTTON_A)
	_ensure_action("cast", [KEY_SPACE], JOY_BUTTON_X)
	_ensure_action("reel", [KEY_SPACE], JOY_BUTTON_X)
	_ensure_action("inventory", [KEY_I], JOY_BUTTON_Y)
	_ensure_action("pause", [KEY_ESCAPE], JOY_BUTTON_START)
	_ensure_action("map", [KEY_M], JOY_BUTTON_BACK)
	_ensure_action("skill_tree", [KEY_K], JOY_BUTTON_RIGHT_STICK)
	_ensure_action("achievements", [KEY_J], JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_action("camera_zoom_in", [KEY_EQUAL])
	_ensure_action("camera_zoom_out", [KEY_MINUS])

func _ensure_action(action_name: StringName, keys: Array, joy_button: int = -1, joy_axis: int = -1, axis_value: float = 0.0) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
	var existing_events := InputMap.action_get_events(action_name)
	for keycode in keys:
		var found := false
		for input_event in existing_events:
			if input_event is InputEventKey and input_event.keycode == keycode:
				found = true
				break
		if not found:
			var key_event := InputEventKey.new()
			key_event.keycode = keycode
			InputMap.action_add_event(action_name, key_event)
	if joy_button >= 0:
		var button_found := false
		for input_event in existing_events:
			if input_event is InputEventJoypadButton and input_event.button_index == joy_button:
				button_found = true
				break
		if not button_found:
			var button_event := InputEventJoypadButton.new()
			button_event.button_index = joy_button
			InputMap.action_add_event(action_name, button_event)
	if joy_axis >= 0:
		var axis_event := InputEventJoypadMotion.new()
		axis_event.axis = joy_axis
		axis_event.axis_value = axis_value
		InputMap.action_add_event(action_name, axis_event)
