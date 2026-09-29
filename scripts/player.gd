extends CharacterBody2D

const WALK_SPEED := 205.0
const FAST_SPEED := 300.0
const SPRITE_SCALE := 0.56
const WORLD_SIZE := Vector2(3200.0, 2400.0)

@onready var visual: Sprite2D = $Sprite2D
var walk_phase := 0.0

func _ready() -> void:
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * SPRITE_SCALE
	visual.position = Vector2(0, -float(visual.texture.get_height()) * SPRITE_SCALE * 0.5)
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.0

func _physics_process(delta: float) -> void:
	var horizontal := 0.0
	var vertical := 0.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		horizontal += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		horizontal -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		vertical += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		vertical -= 1.0
	var direction := Vector2(horizontal, vertical)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	if direction != Vector2.ZERO:
		walk_phase += delta * (15.0 if Input.is_key_pressed(KEY_SHIFT) else 12.0)
		visual.position.y = -float(visual.texture.get_height()) * SPRITE_SCALE * 0.5 - absf(sin(walk_phase)) * 2.3
		visual.rotation = clampf(direction.x * 0.035, -0.035, 0.035)
		if absf(direction.x) > 0.1:
			visual.flip_h = direction.x < 0.0
	else:
		visual.position.y = move_toward(visual.position.y, -float(visual.texture.get_height()) * SPRITE_SCALE * 0.5, delta * 12.0)
		visual.rotation = move_toward(visual.rotation, 0.0, delta * 0.2)

	var pace := FAST_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	velocity = direction * pace
	move_and_slide()
	position.x = clampf(position.x, 24.0, WORLD_SIZE.x - 24.0)
	position.y = clampf(position.y, 24.0, WORLD_SIZE.y - 24.0)

func _draw() -> void:
	# Soft oval foot shadow: keeps the small sprite grounded against the painterly grass.
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		points.append(Vector2(cos(angle) * 12.0, -1.5 + sin(angle) * 4.0))
	draw_colored_polygon(points, Color(0.14, 0.16, 0.12, 0.34))
