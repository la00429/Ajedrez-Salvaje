class_name Board
extends Node3D
## Tablero 8x8 en 3D de Ajedrez Salvaje.
##
## Administra la matriz de casillas y qué ocupa cada posición: colocar,
## mover y retirar piezas, consultar ocupación, límites y vecindades.
## [b]No valida reglas de ajedrez[/b]: eso le corresponde al módulo de piezas
## (movement_validator.gd). El tablero solo comprueba que la operación sea
## posible físicamente (dentro de los límites, origen ocupado, destino libre).
##
## Convención de coordenadas: [code]Vector2i(columna, fila)[/code], con
## columna 0-7 = a-h y fila 0-7 = 1-8. Por ejemplo, [code]Vector2i(4, 3)[/code]
## es "e4".
##
## En el espacio local del tablero: el centro está en el origen, la cara
## superior de las casillas en y = 0, la columna a hacia -X y la fila 1
## (jugador) hacia +Z, es decir, del lado de una cámara ubicada en +Z.
##
## Cualquier [Node3D] puede ocupar una casilla: piezas, el cazador neutral
## o especies invasoras. Hay un solo ocupante por casilla. Los clics se
## detectan con un rayo desde la cámara activa: no hace falta física.

## Clic izquierdo sobre una casilla (o sobre la pieza que la ocupa).
signal cell_clicked(coord: Vector2i)
## Clic derecho sobre una casilla (útil para cancelar una selección).
signal cell_right_clicked(coord: Vector2i)
## El cursor pasó a otra casilla. Recibe [constant INVALID] al salir del tablero.
signal cell_hovered(coord: Vector2i)
## Se colocó un ocupante en el tablero.
signal piece_placed(piece: Node3D, coord: Vector2i)
## Se retiró un ocupante del tablero (capturado, talado, destruido...).
signal piece_removed(piece: Node3D, coord: Vector2i)
## Un ocupante se movió de una casilla a otra.
signal piece_moved(piece: Node3D, from: Vector2i, to: Vector2i)
## Cambió el estado de bloqueo de una casilla.
signal cell_blocked_changed(coord: Vector2i, blocked: bool)

## Número de casillas por lado.
const SIZE := 8
## Coordenada inválida (fuera del tablero o "no encontrada").
const INVALID := Vector2i(-1, -1)
## Letras de las columnas, de la a a la h.
const FILES := "abcdefgh"

## Direcciones ortogonales. "Norte" avanza hacia la fila 8.
const NORTH := Vector2i(0, 1)
const SOUTH := Vector2i(0, -1)
const EAST := Vector2i(1, 0)
const WEST := Vector2i(-1, 0)
## En el orden de la partición del documento: [0, .25) N, [.25, .5) S, [.5, .75) E, [.75, 1) O.
const ORTHOGONAL_DIRECTIONS: Array[Vector2i] = [NORTH, SOUTH, EAST, WEST]

## Altura por defecto (en casillas) para detectar clics sobre una pieza.
## Una pieza puede definir la suya con [code]set_meta(&"board_pick_height", alto)[/code].
const PICK_HEIGHT := 1.1
## Radio (en casillas) del cilindro con que se detectan clics sobre una pieza.
const PICK_RADIUS := 0.3
const PICK_HEIGHT_META := &"board_pick_height"
const PICK_STEPS := 32
const BASE_SCALE_META := &"board_base_scale"
const SLAB_DEPTH := 0.24
const TINY := Vector3(0.001, 0.001, 0.001)

const TILE_SHADER := preload("res://scenes/board/tile.gdshader")
const BoardEffect := preload("res://scripts/board/board_effect.gd")

## Escena usada para crear cada casilla.
@export var cell_scene: PackedScene = preload("res://scenes/board/Cell.tscn")
## Apariencia del tablero. Si es null se usa el tema del Páramo.
@export var board_theme: BoardTheme:
	set(value):
		board_theme = value if value else BoardTheme.new()
		_apply_theme()
## Lado de cada casilla en unidades del mundo.
@export_range(0.25, 4.0, 0.05) var cell_size := 1.0:
	set(value):
		cell_size = value
		_apply_theme() # la escala de la textura depende del tamaño de casilla
## Muestra las letras (a-h) y números (1-8) grabados en el marco.
@export var show_coordinates := true:
	set(value):
		show_coordinates = value
		_build_frame()
## Activa animaciones (aparición, saltos, polvo). Desactivar en pruebas.
@export var animations_enabled := true
## Animación de entrada de casillas y piezas al iniciar.
@export var play_intro_on_ready := true
## Duración base en segundos del salto al mover un ocupante. 0 = instantáneo.
@export_range(0.0, 1.5, 0.01) var move_duration := 0.34
## Si es false, el tablero ignora clics y cursor (por ejemplo, en el turno rival).
@export var input_enabled := true:
	set(value):
		input_enabled = value
		if not input_enabled:
			_set_hovered(INVALID)

var _cells: Array[Array] = [] # _cells[x][y] -> Cell
var _occupants: Dictionary[Vector2i, Node3D] = {}
var _tweens: Dictionary[Node3D, Tween] = {}
var _hovered := INVALID
var _intro_end_msec := 0
var _frame_layer: Node3D
var _cells_layer: Node3D
var _pieces_layer: Node3D
var _effects_layer: Node3D
var _light_material := ShaderMaterial.new()
var _dark_material := ShaderMaterial.new()


func _init() -> void:
	_light_material.shader = TILE_SHADER
	_dark_material.shader = TILE_SHADER
	if board_theme == null:
		board_theme = BoardTheme.new()


func _notification(what: int) -> void:
	# Al instanciar Board.tscn el tablero queda listo de inmediato, así se
	# pueden colocar piezas antes de agregarlo a la escena.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_setup()


func _ready() -> void:
	_setup()
	if play_intro_on_ready:
		play_intro()


func _setup() -> void:
	if not _cells.is_empty():
		return
	_frame_layer = _get_or_create_layer(&"Frame")
	_cells_layer = _get_or_create_layer(&"Cells")
	_pieces_layer = _get_or_create_layer(&"Pieces")
	_effects_layer = _get_or_create_layer(&"Effects")
	_build_cells()
	_build_frame()


# ---------------------------------------------------------------------------
# Coordenadas y geometría
# ---------------------------------------------------------------------------

## true si la coordenada está dentro del tablero 8x8.
static func is_inside(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < SIZE and coord.y >= 0 and coord.y < SIZE


## true si la casilla es clara. a1 es oscura y h1 es clara, como en el ajedrez real.
static func is_light_square(coord: Vector2i) -> bool:
	return (coord.x + coord.y) % 2 == 1


## Convierte una coordenada a notación algebraica: Vector2i(4, 3) -> "e4".
## Devuelve "" si está fuera del tablero.
static func coord_to_algebraic(coord: Vector2i) -> String:
	if not is_inside(coord):
		return ""
	return FILES[coord.x] + str(coord.y + 1)


## Convierte notación algebraica a coordenada: "e4" -> Vector2i(4, 3).
## Devuelve [constant INVALID] si el texto no es una casilla válida.
static func algebraic_to_coord(square: String) -> Vector2i:
	var text := square.strip_edges().to_lower()
	if text.length() != 2 or not text[1].is_valid_int():
		return INVALID
	var coord := Vector2i(FILES.find(text[0]), text[1].to_int() - 1)
	return coord if is_inside(coord) else INVALID


## Distancia de Manhattan |dx| + |dy| (usada por los agentes rivales frente al cazador).
static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Distancia de Chebyshev max(|dx|, |dy|): número de pasos de rey entre dos casillas.
static func chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Casillas de la vecindad de Moore de radio [param radius] dentro del tablero,
## sin incluir el centro. Con radio 2 es la vecindad que usan los agentes ABM.
static func get_moore_neighborhood(center: Vector2i, radius: int = 1) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue
			var coord := center + Vector2i(dx, dy)
			if is_inside(coord):
				result.append(coord)
	return result


## Vecinos ortogonales (N, S, E, O) que están dentro del tablero.
static func get_orthogonal_neighbors(center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in ORTHOGONAL_DIRECTIONS:
		var coord := center + direction
		if is_inside(coord):
			result.append(coord)
	return result


## Centro de la cara superior de la casilla, en coordenadas locales del tablero.
func coord_to_position(coord: Vector2i) -> Vector3:
	return Vector3((coord.x - 3.5) * cell_size, 0.0, (3.5 - coord.y) * cell_size)


## Casilla bajo un punto local del tablero (se ignora la altura).
## Devuelve [constant INVALID] si el punto cae fuera.
func position_to_coord(local_position: Vector3) -> Vector2i:
	var coord := Vector2i(
			floori(local_position.x / cell_size + 4.0),
			floori(4.0 - local_position.z / cell_size))
	return coord if is_inside(coord) else INVALID


## Casilla que "toca" un rayo en coordenadas globales (por ejemplo, desde la
## cámara). Si el rayo atraviesa primero el cuerpo de una pieza, devuelve la
## casilla de esa pieza; si no, la casilla donde el rayo llega al tablero.
func ray_to_coord(origin: Vector3, direction: Vector3) -> Vector2i:
	var inverse := global_transform.affine_inverse()
	var o := inverse * origin
	var d := inverse.basis * direction
	if d.y >= -0.000001:
		return INVALID # el rayo no baja hacia el tablero
	var t_floor := -o.y / d.y
	if t_floor < 0.0:
		return INVALID
	var t_top := maxf(0.0, (cell_size * PICK_HEIGHT * 1.5 - o.y) / d.y)
	if not _occupants.is_empty() and t_top < t_floor:
		var radius := cell_size * PICK_RADIUS
		for i in PICK_STEPS + 1:
			var p := o + d * lerpf(t_top, t_floor, float(i) / PICK_STEPS)
			var coord := position_to_coord(p)
			var piece: Node3D = _occupants.get(coord)
			if piece == null:
				continue
			var center := coord_to_position(coord)
			if Vector2(p.x - center.x, p.z - center.z).length() <= radius and p.y <= _pick_height(piece):
				return coord
	return position_to_coord(o + d * t_floor)


## Lado del área de casillas (sin el marco), en unidades del mundo.
func get_board_size() -> float:
	return cell_size * SIZE


## Ancho del marco en unidades del mundo.
func get_frame_width() -> float:
	return cell_size * board_theme.frame_ratio


## Caja local que ocupa el tablero completo, con el marco y la base.
func get_bounds() -> AABB:
	var half := get_board_size() * 0.5 + get_frame_width()
	var bottom := -cell_size * (Cell.TILE_HEIGHT + SLAB_DEPTH)
	var top := cell_size * board_theme.frame_height
	return AABB(Vector3(-half, bottom, -half), Vector3(half * 2.0, top - bottom, half * 2.0))


# ---------------------------------------------------------------------------
# Ocupación
# ---------------------------------------------------------------------------

## Ocupante de la casilla, o null si está vacía o fuera del tablero.
func get_piece_at(coord: Vector2i) -> Node3D:
	return _occupants.get(coord)


## true si la casilla está dentro del tablero y no tiene ocupante.
func is_empty(coord: Vector2i) -> bool:
	return is_inside(coord) and not _occupants.has(coord)


## true si la casilla tiene ocupante.
func is_occupied(coord: Vector2i) -> bool:
	return _occupants.has(coord)


## Coordenada actual de un ocupante, o [constant INVALID] si no está en el tablero.
func find_piece(piece: Node3D) -> Vector2i:
	for coord in _occupants:
		if _occupants[coord] == piece:
			return coord
	return INVALID


## Todas las casillas ocupadas.
func get_occupied_coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_occupants.keys())
	return result


## Todos los ocupantes del tablero.
func get_all_pieces() -> Array[Node3D]:
	var result: Array[Node3D] = []
	result.assign(_occupants.values())
	return result


## Todas las casillas vacías, recorridas de a1 a h8 (fila por fila).
func get_empty_coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in SIZE:
		result.append_array(get_empty_coords_in_row(y))
	return result


## Casillas vacías de una fila (0 = fila 1), ordenadas de la columna a a la h.
func get_empty_coords_in_row(row: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in SIZE:
		var coord := Vector2i(x, row)
		if is_empty(coord):
			result.append(coord)
	return result


## Primera casilla vacía de una fila, de la a a la h, o [constant INVALID] si
## está llena. El vivero la usa para replantar peones en la fila de origen.
func first_empty_in_row(row: int) -> Vector2i:
	var empty := get_empty_coords_in_row(row)
	return empty[0] if not empty.is_empty() else INVALID


## Coloca un ocupante en una casilla vacía. Si el nodo tenía otro padre, pasa
## a ser hijo del tablero. Devuelve false si la casilla está fuera, ocupada,
## o si el nodo ya está en el tablero (en ese caso hay que usar [method move_piece]).
func place_piece(piece: Node3D, coord: Vector2i) -> bool:
	if piece == null:
		push_error("Board.place_piece: la pieza es null.")
		return false
	if not is_empty(coord) or find_piece(piece) != INVALID:
		return false
	_stop_tween(piece)
	if not piece.has_meta(BASE_SCALE_META):
		piece.set_meta(BASE_SCALE_META, piece.scale)
	var parent := piece.get_parent()
	if parent != _pieces_layer:
		if parent:
			parent.remove_child(piece)
		_pieces_layer.add_child(piece)
	piece.position = coord_to_position(coord)
	_occupants[coord] = piece
	if _animating():
		var wait := (_intro_end_msec - Time.get_ticks_msec()) / 1000.0
		if wait > 0.0:
			_drop_in(piece, wait + (SIZE - 1 - coord.y) * 0.04)
		else:
			_pop_in(piece)
	piece_placed.emit(piece, coord)
	return true


## Mueve el ocupante de [param from] a [param to] con un salto animado.
## El destino debe estar vacío: para capturar, primero se retira la pieza del
## destino con [method remove_piece] o [method destroy_piece]. Devuelve false
## si el movimiento no es posible físicamente. No valida reglas de ajedrez.
func move_piece(from: Vector2i, to: Vector2i) -> bool:
	var piece := get_piece_at(from)
	if piece == null or from == to or not is_empty(to):
		return false
	_occupants.erase(from)
	_occupants[to] = piece
	_animate_to(piece, coord_to_position(to))
	piece_moved.emit(piece, from, to)
	return true


## Retira el ocupante de la casilla y lo devuelve [b]sin liberarlo[/b]: el nodo
## sale del árbol de escena y quien lo recibe decide si lo guarda (por ejemplo,
## en el vivero) o lo libera con [method Node.queue_free]. Muestra una nube de
## polvo salvo que [param effect] sea false. Devuelve null si estaba vacía.
func remove_piece(coord: Vector2i, effect: bool = true) -> Node3D:
	var piece := get_piece_at(coord)
	if piece == null:
		return null
	_occupants.erase(coord)
	_stop_tween(piece)
	_pieces_layer.remove_child(piece)
	if effect:
		spawn_effect(coord, board_theme.effect_color)
	piece_removed.emit(piece, coord)
	return piece


## Retira el ocupante de la casilla y lo libera de memoria.
## Devuelve false si la casilla estaba vacía.
func destroy_piece(coord: Vector2i, effect: bool = true) -> bool:
	var piece := remove_piece(coord, effect)
	if piece == null:
		return false
	piece.queue_free()
	return true


## Libera todos los ocupantes del tablero (por ejemplo, al reiniciar un nivel).
func clear_pieces() -> void:
	for coord in get_occupied_coords():
		destroy_piece(coord, false)


# ---------------------------------------------------------------------------
# Estado de las casillas
# ---------------------------------------------------------------------------

## Nodo [Cell] de una coordenada, o null si está fuera del tablero.
func get_cell(coord: Vector2i) -> Cell:
	if not is_inside(coord) or _cells.is_empty():
		return null
	return _cells[coord.x][coord.y]


## Marca o desmarca una casilla como intransitable. El tablero solo guarda
## y muestra este estado; las reglas de movimiento deciden qué significa.
func set_blocked(coord: Vector2i, blocked: bool = true) -> void:
	var cell := get_cell(coord)
	if cell == null or cell.blocked == blocked:
		return
	cell.blocked = blocked
	if blocked:
		spawn_effect(coord, board_theme.ember_color)
	cell_blocked_changed.emit(coord, blocked)


## true si la casilla está marcada como intransitable.
func is_blocked(coord: Vector2i) -> bool:
	var cell := get_cell(coord)
	return cell != null and cell.blocked


## Todas las casillas marcadas como intransitables.
func get_blocked_coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in SIZE:
		for y in SIZE:
			if _cells[x][y].blocked:
				result.append(Vector2i(x, y))
	return result


## Quita el bloqueo de todas las casillas.
func clear_blocked() -> void:
	for coord in get_blocked_coords():
		set_blocked(coord, false)


## Cambia el resaltado de una casilla.
func set_highlight(coord: Vector2i, kind: Cell.Highlight) -> void:
	var cell := get_cell(coord)
	if cell:
		cell.highlight = kind


## Aplica el mismo resaltado a varias casillas (por ejemplo, los movimientos
## válidos que calcula el módulo de piezas). Ignora las que estén fuera.
func highlight_cells(coords: Array, kind: Cell.Highlight) -> void:
	for coord in coords:
		set_highlight(coord, kind)


## Resaltado actual de una casilla ([constant Cell.Highlight.NONE] si está fuera).
func get_highlight(coord: Vector2i) -> Cell.Highlight:
	var cell := get_cell(coord)
	return cell.highlight if cell else Cell.Highlight.NONE


## Quita todos los resaltados del tablero.
func clear_highlights() -> void:
	for column in _cells:
		for cell: Cell in column:
			cell.highlight = Cell.Highlight.NONE


## Cambia solo los colores de las casillas, conservando el resto del tema.
func apply_palette(light: Color, dark: Color) -> void:
	var t := board_theme.duplicate() as BoardTheme
	t.light_color = light
	t.dark_color = dark
	board_theme = t


# ---------------------------------------------------------------------------
# Animaciones y efectos
# ---------------------------------------------------------------------------

## Animación de entrada: las casillas emergen en ola desde a1 y luego caen
## las piezas fila por fila.
func play_intro() -> void:
	if not animations_enabled or not is_inside_tree():
		return
	var cells_time := 0.0
	var tween := create_tween().set_parallel(true)
	_frame_layer.scale = Vector3(0.92, 0.92, 0.92)
	tween.tween_property(_frame_layer, "scale", Vector3.ONE, 0.6) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for x in SIZE:
		for y in SIZE:
			var cell: Cell = _cells[x][y]
			var delay := 0.15 + (x + y) * 0.035
			cells_time = maxf(cells_time, delay + 0.45)
			cell.position.y = -cell_size * 0.5
			cell.scale = Vector3(0.6, 0.6, 0.6)
			tween.tween_property(cell, "position:y", 0.0, 0.45).set_delay(delay) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(cell, "scale", Vector3.ONE, 0.45).set_delay(delay) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_end_msec = Time.get_ticks_msec() + int(cells_time * 1000.0)
	for coord in _occupants:
		_drop_in(_occupants[coord], cells_time + (SIZE - 1 - coord.y) * 0.04)


## Muestra un efecto de partículas y onda en una casilla.
func spawn_effect(coord: Vector2i, color: Color) -> void:
	if not _animating() or not is_inside(coord):
		return
	var effect := BoardEffect.new()
	effect.color = color
	effect.radius = cell_size * 0.5
	effect.position = coord_to_position(coord) + Vector3.UP * cell_size * 0.02
	_effects_layer.add_child(effect)


func _animating() -> bool:
	return animations_enabled and is_inside_tree()


func _pick_height(piece: Node3D) -> float:
	return float(piece.get_meta(PICK_HEIGHT_META, PICK_HEIGHT)) * cell_size


func _pop_in(piece: Node3D) -> void:
	_stop_tween(piece)
	var base := _base_scale(piece)
	piece.scale = base * 0.001
	var tween := piece.create_tween()
	tween.tween_property(piece, "scale", base, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_track_tween(piece, tween)


func _drop_in(piece: Node3D, delay: float) -> void:
	_stop_tween(piece)
	var base := _base_scale(piece)
	var target := piece.position
	piece.scale = base * 0.001
	piece.position = target + Vector3.UP * cell_size * 1.6
	var tween := piece.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(piece, "scale", base, 0.12)
	tween.parallel().tween_property(piece, "position", target, 0.55) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_track_tween(piece, tween)


func _animate_to(piece: Node3D, target: Vector3) -> void:
	_stop_tween(piece)
	if not _animating() or move_duration <= 0.0 or not piece.is_inside_tree():
		piece.position = target
		return
	var start := piece.position
	var distance := Vector2(target.x - start.x, target.z - start.z).length()
	var hop := cell_size * (0.35 + 0.22 * minf(distance / cell_size, 3.0))
	var duration := move_duration * clampf(sqrt(distance / cell_size), 1.0, 1.8)
	var base := _base_scale(piece)
	var hop_step := func(t: float) -> void:
		piece.position = start.lerp(target, t) + Vector3.UP * sin(t * PI) * hop
	var tween := piece.create_tween()
	tween.tween_method(hop_step, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "scale", base * Vector3(1.12, 0.82, 1.12), 0.07)
	tween.tween_property(piece, "scale", base, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_track_tween(piece, tween)


func _track_tween(piece: Node3D, tween: Tween) -> void:
	_tweens[piece] = tween
	var forget := func() -> void:
		if _tweens.get(piece) == tween:
			_tweens.erase(piece)
	tween.finished.connect(forget)


func _stop_tween(piece: Node3D) -> void:
	var tween: Tween = _tweens.get(piece)
	if tween and tween.is_valid():
		tween.kill()
	_tweens.erase(piece)
	if piece.has_meta(BASE_SCALE_META):
		piece.scale = piece.get_meta(BASE_SCALE_META)


func _base_scale(piece: Node3D) -> Vector3:
	return piece.get_meta(BASE_SCALE_META, piece.scale)


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or _cells.is_empty():
		return
	if event is InputEventMouseMotion:
		_set_hovered(_coord_at_screen(event.position))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
			return
		var coord := _coord_at_screen(event.position)
		if coord == INVALID:
			return
		get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_LEFT:
			cell_clicked.emit(coord)
		else:
			cell_right_clicked.emit(coord)


func _coord_at_screen(screen_position: Vector2) -> Vector2i:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return INVALID
	return ray_to_coord(camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))


func _set_hovered(coord: Vector2i) -> void:
	if coord == _hovered:
		return
	var previous := get_cell(_hovered)
	if previous:
		previous.hovered = false
	var current := get_cell(coord)
	if current:
		current.hovered = true
	if (_hovered == INVALID) != (coord == INVALID):
		Input.set_default_cursor_shape(
				Input.CURSOR_ARROW if coord == INVALID else Input.CURSOR_POINTING_HAND)
	_hovered = coord
	cell_hovered.emit(coord)


# ---------------------------------------------------------------------------
# Construcción
# ---------------------------------------------------------------------------

func _get_or_create_layer(layer_name: StringName) -> Node3D:
	var layer := get_node_or_null(NodePath(layer_name)) as Node3D
	if layer == null:
		layer = Node3D.new()
		layer.name = layer_name
		add_child(layer)
	return layer


func _build_cells() -> void:
	for x in SIZE:
		var column: Array[Cell] = []
		for y in SIZE:
			var cell := cell_scene.instantiate() as Cell
			cell.name = "Cell_" + coord_to_algebraic(Vector2i(x, y))
			_cells_layer.add_child(cell)
			column.append(cell)
		_cells.append(column)
	_refresh_cells()


func _apply_theme() -> void:
	for pair in [[_light_material, board_theme.light_color], [_dark_material, board_theme.dark_color]]:
		var material: ShaderMaterial = pair[0]
		material.set_shader_parameter(&"base_color", pair[1])
		material.set_shader_parameter(&"texture_strength", board_theme.texture_strength)
		material.set_shader_parameter(&"texture_scale", board_theme.texture_scale / cell_size)
		material.set_shader_parameter(&"roughness_value", board_theme.tile_roughness)
	_refresh_cells()
	_build_frame()


func _refresh_cells() -> void:
	if _cells.is_empty():
		return
	for x in SIZE:
		for y in SIZE:
			var coord := Vector2i(x, y)
			var light := is_light_square(coord)
			var cell: Cell = _cells[x][y]
			cell.setup(coord, cell_size, light, _light_material if light else _dark_material, board_theme)
			cell.position = coord_to_position(coord)
	for coord in _occupants:
		_stop_tween(_occupants[coord])
		_occupants[coord].position = coord_to_position(coord)


## Base, borde elevado, filete decorativo y coordenadas grabadas.
func _build_frame() -> void:
	if _frame_layer == null:
		return
	for child in _frame_layer.get_children():
		_frame_layer.remove_child(child)
		child.queue_free()

	var half := get_board_size() * 0.5
	var frame := get_frame_width()
	var tile_depth := cell_size * Cell.TILE_HEIGHT
	var slab := cell_size * SLAB_DEPTH
	var rim := cell_size * board_theme.frame_height
	var outer := half + frame

	var wood := _frame_material(board_theme.frame_color, 0.55, 0.0)
	var base := _frame_material(board_theme.frame_color.darkened(0.45), 0.8, 0.0)
	var accent := _frame_material(board_theme.frame_accent_color, 0.35, 0.65)

	# Losa base: se ve en las juntas entre casillas.
	_add_box(Vector3(0.0, -tile_depth - slab * 0.5, 0.0), Vector3(outer * 2.0, slab, outer * 2.0), base)
	# Borde elevado (cuatro barras).
	if frame > 0.0:
		var height := rim + tile_depth
		var center_y := (rim - tile_depth) * 0.5
		var z_bar := half + frame * 0.5
		_add_box(Vector3(0.0, center_y, z_bar), Vector3(outer * 2.0, height, frame), wood)
		_add_box(Vector3(0.0, center_y, -z_bar), Vector3(outer * 2.0, height, frame), wood)
		_add_box(Vector3(z_bar, center_y, 0.0), Vector3(frame, height, half * 2.0), wood)
		_add_box(Vector3(-z_bar, center_y, 0.0), Vector3(frame, height, half * 2.0), wood)
		# Filete metálico sobre el borde y canto interior.
		var line := cell_size * 0.025
		var inset := half + frame * 0.72
		var y := rim + cell_size * 0.004
		_add_box(Vector3(0.0, y, inset), Vector3(inset * 2.0 + line, cell_size * 0.008, line), accent)
		_add_box(Vector3(0.0, y, -inset), Vector3(inset * 2.0 + line, cell_size * 0.008, line), accent)
		_add_box(Vector3(inset, y, 0.0), Vector3(line, cell_size * 0.008, inset * 2.0), accent)
		_add_box(Vector3(-inset, y, 0.0), Vector3(line, cell_size * 0.008, inset * 2.0), accent)
		if show_coordinates:
			_add_coordinates(half, frame, rim)


func _add_coordinates(half: float, frame: float, rim: float) -> void:
	var y := rim + cell_size * 0.006
	var offset := half + frame * 0.36
	for i in SIZE:
		var along := (i - 3.5) * cell_size
		_add_label(FILES[i].to_upper(), Vector3(along, y, offset), frame)
		_add_label(FILES[i].to_upper(), Vector3(along, y, -offset), frame)
		var rank_z := (3.5 - i) * cell_size
		_add_label(str(i + 1), Vector3(-offset, y, rank_z), frame)
		_add_label(str(i + 1), Vector3(offset, y, rank_z), frame)


func _add_label(text: String, at: Vector3, frame: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = frame * 0.4 / 96.0
	label.outline_size = 0
	label.modulate = board_theme.label_color
	label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_frame_layer.add_child(label)


func _add_box(at: Vector3, size: Vector3, material: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	_frame_layer.add_child(mesh)


func _frame_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
