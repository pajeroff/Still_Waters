extends Camera2D

const ZOOM_LEVELS: Array[float] = [1.0, 2.0]

@export var map_limits := Rect2i(-400, -32, 896, 480)
@export var smooth_speed := 8.0

var _zoom_index := 0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = smooth_speed
	limit_left = map_limits.position.x
	limit_top = map_limits.position.y
	limit_right = map_limits.end.x
	limit_bottom = map_limits.end.y
	zoom = Vector2.ONE * ZOOM_LEVELS[_zoom_index]
	make_current()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(-1)
	elif event.is_action_pressed("camera_zoom_in"):
		_set_zoom(1)
	elif event.is_action_pressed("camera_zoom_out"):
		_set_zoom(-1)

func _set_zoom(direction: int) -> void:
	_zoom_index = clampi(_zoom_index + direction, 0, ZOOM_LEVELS.size() - 1)
	var target: Vector2 = Vector2.ONE * float(ZOOM_LEVELS[_zoom_index])
	create_tween().tween_property(self, "zoom", target, 0.14)
