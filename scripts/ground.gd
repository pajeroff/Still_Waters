extends Node2D

const WORLD_SIZE := Vector2(3200.0, 2400.0)
const LAKE_CENTER := Vector2(1870.0, 850.0)

var rng := RandomNumberGenerator.new()
var ground_marks: Array[Dictionary] = []
var path_points := PackedVector2Array([
	Vector2(-40, 2360), Vector2(160, 2160), Vector2(385, 1980),
	Vector2(650, 1820), Vector2(900, 1690), Vector2(1110, 1530),
	Vector2(1280, 1370), Vector2(1450, 1190), Vector2(1580, 1080)
])

func _ready() -> void:
	rng.seed = 709214
	for i in range(620):
		var p := Vector2(rng.randf_range(20.0, WORLD_SIZE.x - 20.0), rng.randf_range(20.0, WORLD_SIZE.y - 20.0))
		ground_marks.append({
			"position": p,
			"radius": rng.randf_range(3.0, 19.0),
			"color": Color.from_hsv(rng.randf_range(0.19, 0.25), rng.randf_range(0.18, 0.34), rng.randf_range(0.29, 0.43), rng.randf_range(0.10, 0.28))
		})
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("536640"))

	# Soft, broken patches of moss keep the clearing from reading as a flat fill.
	for mark in ground_marks:
		draw_circle(mark.position, mark.radius, mark.color)

	_draw_lake()
	_draw_path()
	_draw_grass_strokes()

	# A discreet boundary edge lets the player read the extent of the small demo map.
	draw_rect(Rect2(Vector2(16, 16), WORLD_SIZE - Vector2(32, 32)), Color(0.20, 0.26, 0.19, 0.55), false, 2.0)

func _draw_lake() -> void:
	# Sandy banks, a shallow turquoise lip, then the deeper still water.
	_draw_ellipse(LAKE_CENTER, Vector2(455, 300), Color("b39a71"), 76, 0.035)
	_draw_ellipse(LAKE_CENTER + Vector2(0, -2), Vector2(412, 267), Color("78947b"), 76, 0.025)
	_draw_ellipse(LAKE_CENTER + Vector2(2, -5), Vector2(382, 239), Color("477d7d"), 76, 0.022)
	_draw_ellipse(LAKE_CENTER + Vector2(8, -8), Vector2(360, 219), Color("315f67"), 76, 0.018)

	# Long, low-contrast reflections catch the light without competing with the player.
	for i in range(17):
		var y := LAKE_CENTER.y - 166.0 + float(i) * 19.0
		var inset := absf(float(i) - 8.0) * 13.0
		var x1 := LAKE_CENTER.x - 284.0 + inset
		var x2 := LAKE_CENTER.x + 260.0 - inset
		if x2 > x1 + 35.0:
			var line := PackedVector2Array([Vector2(x1, y), Vector2((x1 + x2) * 0.5 - 16.0, y - 1.5), Vector2(x2, y)])
			draw_polyline(line, Color(0.72, 0.85, 0.79, 0.13), 2.0, true)

	# A few tiny glints suggest ripples on the breeze.
	for i in range(25):
		var x := LAKE_CENTER.x - 255.0 + float(i % 5) * 111.0 + float((i * 17) % 19)
		var y := LAKE_CENTER.y - 140.0 + float(i / 5) * 64.0 + float((i * 11) % 17)
		draw_line(Vector2(x, y), Vector2(x + 20.0 + float(i % 3) * 5.0, y), Color(0.78, 0.88, 0.82, 0.24), 2.0, true)

func _draw_path() -> void:
	# A gently winding ochre footpath leads from the lower edge to the lakeshore.
	_draw_rounded_polyline(path_points, 112.0, Color("76684d"))
	_draw_rounded_polyline(path_points, 99.0, Color("a78c64"))
	_draw_rounded_polyline(path_points, 3.0, Color(0.83, 0.73, 0.55, 0.22))

	# Scattered pale stones embedded in the path.
	for i in range(56):
		var t := rng.randf()
		var segment := mini(int(t * float(path_points.size() - 1)), path_points.size() - 2)
		var p := path_points[segment].lerp(path_points[segment + 1], rng.randf())
		p += Vector2(rng.randf_range(-36.0, 36.0), rng.randf_range(-38.0, 38.0))
		draw_circle(p, rng.randf_range(1.0, 3.0), Color(0.87, 0.81, 0.67, 0.25))

func _draw_rounded_polyline(points: PackedVector2Array, width: float, color: Color) -> void:
	draw_polyline(points, color, width, true)
	var radius := width * 0.5
	for p in points:
		draw_circle(p, radius, color)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color, segments: int, wobble: float) -> void:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		var wave := 1.0 + sin(angle * 5.0 + 0.7) * wobble + cos(angle * 9.0) * wobble * 0.35
		points.append(center + Vector2(cos(angle) * radii.x * wave, sin(angle) * radii.y * wave))
	draw_colored_polygon(points, color)

func _draw_grass_strokes() -> void:
	# Handfuls of fine blades, mostly away from the trail and the beach.
	var blades_rng := RandomNumberGenerator.new()
	blades_rng.seed = 2086
	for i in range(460):
		var p := Vector2(blades_rng.randf_range(30.0, WORLD_SIZE.x - 30.0), blades_rng.randf_range(30.0, WORLD_SIZE.y - 30.0))
		if _near_path(p, 74.0) or _inside_lake(p, 480.0, 325.0):
			continue
		var h := blades_rng.randf_range(3.0, 9.0)
		var tint := Color(0.74, 0.79, 0.51, blades_rng.randf_range(0.12, 0.34))
		draw_line(p, p + Vector2(blades_rng.randf_range(-3.0, 3.0), -h), tint, 1.4, true)
		draw_line(p + Vector2(2.0, 0.0), p + Vector2(blades_rng.randf_range(1.0, 5.0), -h * 0.68), tint, 1.1, true)

func _inside_lake(p: Vector2, rx: float, ry: float) -> bool:
	var q := (p - LAKE_CENTER) / Vector2(rx, ry)
	return q.length_squared() < 1.0

func _near_path(p: Vector2, radius: float) -> bool:
	for i in range(path_points.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(p, path_points[i], path_points[i + 1])
		if closest.distance_to(p) < radius:
			return true
	return false
