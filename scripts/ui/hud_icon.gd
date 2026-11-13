extends Control
## Ícono vectorial pequeño para el HUD, dibujado por código (no depende de
## fuentes con símbolos, que cambian entre sistemas operativos).
##
## kind: &"drop" (agua), &"sun", &"rain", &"frost", &"fire" (clima),
## &"sprout" (vivero), &"pause", &"view", &"list", &"dot".

var kind: StringName = &"dot":
	set(value):
		kind = value
		queue_redraw()
var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(18, 18)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var w := maxf(1.5, s * 0.1)
	var shadow := Color(0, 0, 0, 0.45)
	# Sombra suave: el mismo dibujo desplazado.
	draw_set_transform(Vector2(0, 1.2))
	_shape(c, s, w, shadow)
	draw_set_transform(Vector2.ZERO)
	_shape(c, s, w, color)


func _shape(c: Vector2, s: float, w: float, col: Color) -> void:
	match kind:
		&"drop":
			var points := PackedVector2Array()
			for i in 17:
				var t := PI * i / 16.0
				points.append(c + Vector2(cos(t) * s * 0.28, sin(t) * s * 0.28 + s * 0.12))
			points.append(c + Vector2(0, -s * 0.42))
			draw_colored_polygon(points, col)
		&"sun":
			draw_circle(c, s * 0.2, col, true, -1.0, true)
			for i in 8:
				var d := Vector2.from_angle(TAU * i / 8.0)
				draw_line(c + d * s * 0.3, c + d * s * 0.44, col, w, true)
		&"rain":
			_cloud(c + Vector2(0, -s * 0.1), s, col)
			for x in [-0.18, 0.0, 0.18]:
				draw_line(c + Vector2(x * s, s * 0.18), c + Vector2(x * s - s * 0.06, s * 0.4), col, w, true)
		&"frost":
			for i in 3:
				var d := Vector2.from_angle(PI * i / 3.0)
				draw_line(c - d * s * 0.42, c + d * s * 0.42, col, w, true)
		&"fire":
			var points := PackedVector2Array([
				c + Vector2(0, -s * 0.45), c + Vector2(s * 0.24, -s * 0.05), c + Vector2(s * 0.28, s * 0.2),
				c + Vector2(s * 0.12, s * 0.42), c + Vector2(-s * 0.12, s * 0.42), c + Vector2(-s * 0.28, s * 0.2),
				c + Vector2(-s * 0.18, -s * 0.12), c + Vector2(-s * 0.06, s * 0.02),
			])
			draw_colored_polygon(points, col)
		&"sprout":
			draw_line(c + Vector2(0, s * 0.42), c + Vector2(0, -s * 0.05), col, w, true)
			_leaf(c + Vector2(0, -s * 0.05), -0.75, s, col)
			_leaf(c + Vector2(0, s * 0.1), 0.85, s * 0.85, col)
		&"pause":
			draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.32), Vector2(s * 0.17, s * 0.64)), col)
			draw_rect(Rect2(c + Vector2(s * 0.09, -s * 0.32), Vector2(s * 0.17, s * 0.64)), col)
		&"view":
			# Montañas: cambia a la vista panorámica.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.45, s * 0.3), c + Vector2(-s * 0.1, -s * 0.25),
					c + Vector2(s * 0.12, s * 0.05), c + Vector2(s * 0.24, -s * 0.1), c + Vector2(s * 0.45, s * 0.3)]), col)
		&"list":
			for i in 3:
				var y := c.y + (i - 1) * s * 0.28
				draw_circle(Vector2(c.x - s * 0.34, y), w * 0.7, col, true, -1.0, true)
				draw_line(Vector2(c.x - s * 0.18, y), Vector2(c.x + s * 0.42, y), col, w, true)
		_:
			draw_circle(c, s * 0.42, col, true, -1.0, true)


func _cloud(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.16, s * 0.04), s * 0.17, col, true, -1.0, true)
	draw_circle(c + Vector2(s * 0.06, -s * 0.06), s * 0.22, col, true, -1.0, true)
	draw_circle(c + Vector2(s * 0.24, s * 0.05), s * 0.15, col, true, -1.0, true)
	draw_rect(Rect2(c + Vector2(-s * 0.16, s * 0.02), Vector2(s * 0.4, s * 0.17)), col)


func _leaf(base: Vector2, angle: float, s: float, col: Color) -> void:
	var points := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		points.append(Vector2(t * s * 0.38, sin(t * PI) * s * 0.13))
	for i in range(7, 0, -1):
		var t := float(i) / 8.0
		points.append(Vector2(t * s * 0.38, -sin(t * PI) * s * 0.05))
	for i in points.size():
		points[i] = base + points[i].rotated(angle)
	draw_colored_polygon(points, col)
