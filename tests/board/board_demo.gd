extends Node3D
## Demo interactiva del módulo de tablero 3D (Integrante 1).
##
## Abrir tests/board/board_demo.tscn en el editor de Godot y ejecutar la escena
## actual: F6 en Windows/Linux, Cmd+R en macOS. Desde la terminal:
##   godot --path . res://tests/board/board_demo.tscn
##
## Las fichas son de relleno y se mueven como un rey (una casilla en cualquier
## dirección) solo para probar el tablero. Las reglas reales de ajedrez son
## del módulo de piezas, y la caminata real del cazador (generador de Lehmer)
## es del módulo de simulación.

const DemoPiece := preload("res://tests/board/demo_piece_3d.gd")
const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

const PLAYER := 0
const RIVAL := 1
const NEUTRAL := -1
const PANEL_WIDTH := 360.0
const MARGIN := 24.0
const MAX_EVENTS := 4
const PIECE_SCALE := 1.3

const CREAM := Color("#f1ead8")
const MUTED := Color(0.94, 0.92, 0.85, 0.6)

## Bioma con el que arranca la demo (lo asigna el menú principal).
@export var initial_theme: StringName = &""

@onready var board: Board = $Board
@onready var camera: Camera3D = $Camera3D
@onready var environment: Node3D = $Environment
@onready var ui_layer: CanvasLayer = $UI

var _selected := Board.INVALID
var _hovered := Board.INVALID
var _last_move: Array[Vector2i] = []
var _hunter: Node3D
var _events: PackedStringArray = []
var _theme_name: StringName = &"paramo"
var _rng := RandomNumberGenerator.new()

# Cámara orbital alrededor del centro del tablero.
const PLAY_VIEW := Vector3(0.0, 50.0, 17.0) # giro, inclinación (grados), distancia
const PANORAMA_VIEW := Vector3(-0.5, 11.0, 30.0)
var _yaw := deg_to_rad(PLAY_VIEW.x)
var _pitch := deg_to_rad(PLAY_VIEW.y)
var _distance := PLAY_VIEW.z
var _orbiting := false
var _panorama := false
var _camera_tween: Tween

var _panel: PanelContainer
var _biome_label: Label
var _square_label: Label
var _detail_label: Label
var _events_label: Label
var _theme_buttons: Dictionary = {}


func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_build_ui()
	board.cell_clicked.connect(_on_cell_clicked)
	board.cell_right_clicked.connect(_on_cell_right_clicked)
	board.cell_hovered.connect(_on_cell_hovered)
	board.piece_moved.connect(_on_piece_moved)
	board.piece_removed.connect(_on_piece_removed)
	board.cell_blocked_changed.connect(_on_cell_blocked_changed)
	get_viewport().size_changed.connect(_layout)

	if initial_theme != &"":
		_theme_name = initial_theme
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--theme="):
			_theme_name = StringName(arg.trim_prefix("--theme="))
		elif arg.begins_with("--yaw="):
			_yaw = deg_to_rad(arg.trim_prefix("--yaw=").to_float())
		elif arg.begins_with("--distance="):
			_distance = arg.trim_prefix("--distance=").to_float()
		elif arg.begins_with("--pitch="):
			_pitch = deg_to_rad(arg.trim_prefix("--pitch=").to_float())
	camera.fov = 40.0
	_set_theme(_theme_name)
	_layout()
	_reset()
	if args.has("--demo-shot"):
		_play_screenshot_scene()
	elif not args.has("--no-intro"):
		_play_camera_intro()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(-0.8)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(0.8)
			MOUSE_BUTTON_MIDDLE:
				_orbiting = event.pressed
	elif event is InputEventMouseMotion and _orbiting:
		_yaw -= event.relative.x * 0.006
		_pitch = clampf(_pitch + event.relative.y * 0.004, deg_to_rad(8.0), deg_to_rad(85.0))
		_update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_hunter_step()
			KEY_C:
				_random_catastrophe()
			KEY_R:
				_reset()
			KEY_Q:
				_rotate_camera(-PI / 8.0)
			KEY_E:
				_rotate_camera(PI / 8.0)
			KEY_V:
				_toggle_panorama()
			KEY_ESCAPE:
				_go_to_menu()
			KEY_1, KEY_2, KEY_3, KEY_4:
				_set_theme(BoardTheme.PRESETS[event.keycode - KEY_1])


# ---------------------------------------------------------------------------
# Cámara
# ---------------------------------------------------------------------------

func _rotate_camera(amount: float) -> void:
	_fly_to(Vector3(rad_to_deg(_yaw + amount), rad_to_deg(_pitch), _distance), 0.35)


func _zoom(amount: float) -> void:
	_distance = clampf(_distance + amount, 7.0, 40.0)
	_update_camera()


## Alterna entre la vista de juego y una panorámica baja para ver el paisaje.
func _toggle_panorama() -> void:
	_panorama = not _panorama
	var view := PANORAMA_VIEW if _panorama else PLAY_VIEW
	_fly_to(Vector3(view.x if _panorama else rad_to_deg(_yaw), view.y, view.z), 1.6)


## Entrada cinematográfica: parte de una panorámica baja y baja hasta el tablero.
func _play_camera_intro() -> void:
	_yaw = deg_to_rad(-38.0)
	_pitch = deg_to_rad(9.0)
	_distance = 36.0
	_update_camera()
	_fly_to(PLAY_VIEW, 3.6)


## Mueve la cámara suavemente a (giro, inclinación, distancia) en grados.
func _fly_to(view: Vector3, duration: float) -> void:
	if _camera_tween and _camera_tween.is_valid():
		_camera_tween.kill()
	var from := Vector3(_yaw, _pitch, _distance)
	var to := Vector3(deg_to_rad(view.x), deg_to_rad(view.y), view.z)
	var step := func(t: float) -> void:
		var v := from.lerp(to, t)
		_yaw = v.x
		_pitch = v.y
		_distance = v.z
		_update_camera()
	_camera_tween = create_tween()
	_camera_tween.tween_method(step, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _update_camera() -> void:
	var offset := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch)) * _distance
	var target := Vector3(0.0, -0.2, 0.25)
	camera.position = target + offset
	camera.look_at(target, Vector3.UP)
	# Desplaza la vista para que el tablero quede centrado en el espacio libre
	# a la izquierda del panel.
	var viewport := get_viewport().get_visible_rect().size
	var free_width := viewport.x - PANEL_WIDTH - MARGIN * 2.0
	var visible_width := 2.0 * _distance * tan(deg_to_rad(camera.fov) * 0.5) * viewport.x / viewport.y
	camera.h_offset = (viewport.x * 0.5 - free_width * 0.5) / viewport.x * visible_width


func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	_update_camera()
	_panel.position = Vector2(viewport.x - PANEL_WIDTH - MARGIN, MARGIN)
	_panel.size = Vector2(PANEL_WIDTH, viewport.y - MARGIN * 2.0)


## Vuelve al menú principal (si existe en el proyecto).
func _go_to_menu() -> void:
	if ResourceLoader.exists(MENU_SCENE):
		get_tree().change_scene_to_file(MENU_SCENE)


# ---------------------------------------------------------------------------
# Partida de demostración
# ---------------------------------------------------------------------------

func _reset() -> void:
	board.clear_pieces()
	board.clear_blocked()
	board.clear_highlights()
	_selected = Board.INVALID
	_last_move.clear()
	_events.clear()
	# Conjunto reducido del documento (sección 4.2): 8 peones, 2 caballos y 1 rey por bando.
	for x in Board.SIZE:
		_spawn(PLAYER, &"pawn", Vector2i(x, 1))
		_spawn(RIVAL, &"pawn", Vector2i(x, 6))
	for square in ["b1", "g1"]:
		_spawn(PLAYER, &"knight", Board.algebraic_to_coord(square))
	for square in ["b8", "g8"]:
		_spawn(RIVAL, &"knight", Board.algebraic_to_coord(square))
	_spawn(PLAYER, &"king", Board.algebraic_to_coord("e1"))
	_spawn(RIVAL, &"king", Board.algebraic_to_coord("e8"))
	_hunter = _spawn(NEUTRAL, &"hunter", Board.algebraic_to_coord("d4"))
	_log("Tablero listo: cazador en d4")
	_update_info()


func _spawn(side: int, kind: StringName, coord: Vector2i) -> Node3D:
	var piece := DemoPiece.new()
	piece.side = side
	piece.kind = kind
	piece.scale = Vector3.ONE * PIECE_SCALE
	board.place_piece(piece, coord)
	return piece


func _on_cell_clicked(coord: Vector2i) -> void:
	var kind := board.get_highlight(coord)
	var piece = board.get_piece_at(coord)
	if _selected != Board.INVALID and (kind == Cell.Highlight.MOVE or kind == Cell.Highlight.CAPTURE):
		_move(_selected, coord)
		_deselect()
	elif piece and piece != _hunter and coord != _selected:
		_select(coord)
	else:
		_deselect()
	_update_info()


func _on_cell_right_clicked(coord: Vector2i) -> void:
	board.set_blocked(coord, not board.is_blocked(coord))
	_update_info()


func _on_cell_hovered(coord: Vector2i) -> void:
	_hovered = coord
	_update_info()


func _select(coord: Vector2i) -> void:
	_deselect()
	_selected = coord
	var piece = board.get_piece_at(coord)
	board.set_highlight(coord, Cell.Highlight.SELECTED)
	# Movimiento de demostración (como un rey), NO son reglas de ajedrez reales.
	for target in Board.get_moore_neighborhood(coord, 1):
		if board.is_blocked(target):
			continue
		var other = board.get_piece_at(target)
		if other == null:
			board.set_highlight(target, Cell.Highlight.MOVE)
		elif other.side != piece.side:
			board.set_highlight(target, Cell.Highlight.CAPTURE)


func _deselect() -> void:
	_selected = Board.INVALID
	board.clear_highlights()
	board.highlight_cells(_last_move, Cell.Highlight.LAST_MOVE)
	_update_check()


func _move(from: Vector2i, to: Vector2i) -> void:
	var captured = board.remove_piece(to)
	if captured:
		if captured == _hunter:
			_hunter = null
		captured.queue_free()
	board.move_piece(from, to)
	_last_move = [from, to]


func _hunter_step() -> void:
	if _hunter == null:
		_log("El cazador ya no está en el tablero")
		_update_info()
		return
	var from := board.find_piece(_hunter)
	var options := Board.get_orthogonal_neighbors(from)
	var to: Vector2i = options[_rng.randi() % options.size()]
	if board.is_occupied(to):
		board.destroy_piece(to)
	board.move_piece(from, to)
	_last_move = [from, to]
	_deselect()
	_update_info()


func _random_catastrophe() -> void:
	var candidates := board.get_empty_coords().filter(func(c: Vector2i) -> bool: return not board.is_blocked(c))
	if candidates.is_empty():
		return
	board.set_blocked(candidates[_rng.randi() % candidates.size()])
	_update_info()


## Demo: marca en jaque al rey que tenga una ficha rival adyacente.
func _update_check() -> void:
	for piece in board.get_all_pieces():
		if piece.kind != &"king":
			continue
		var coord := board.find_piece(piece)
		for neighbor in Board.get_moore_neighborhood(coord, 1):
			var other = board.get_piece_at(neighbor)
			if other and other.side != NEUTRAL and other.side != piece.side:
				board.set_highlight(coord, Cell.Highlight.CHECK)
				break


# ---------------------------------------------------------------------------
# Registro de eventos (escucha las señales del tablero)
# ---------------------------------------------------------------------------

func _on_piece_moved(piece: Node3D, from: Vector2i, to: Vector2i) -> void:
	_log("%s  %s → %s" % [_describe(piece), Board.coord_to_algebraic(from), Board.coord_to_algebraic(to)])


func _on_piece_removed(piece: Node3D, coord: Vector2i) -> void:
	_log("%s retirado de %s" % [_describe(piece), Board.coord_to_algebraic(coord)])


func _on_cell_blocked_changed(coord: Vector2i, blocked: bool) -> void:
	if blocked:
		_log("Catástrofe en %s: casilla intransitable" % Board.coord_to_algebraic(coord))
	else:
		_log("%s vuelve a ser transitable" % Board.coord_to_algebraic(coord))


func _describe(piece: Node3D) -> String:
	if piece.side == NEUTRAL:
		return piece.display_name()
	return "%s %s" % [piece.display_name(), "(jugador)" if piece.side == PLAYER else "(rival)"]


func _log(text: String) -> void:
	_events.insert(0, text)
	if _events.size() > MAX_EVENTS:
		_events.resize(MAX_EVENTS)
	if _events_label:
		_events_label.text = "\n".join(_events)


# ---------------------------------------------------------------------------
# Interfaz
# ---------------------------------------------------------------------------

func _set_theme(theme_name: StringName) -> void:
	if not theme_name in BoardTheme.PRESETS:
		theme_name = &"paramo"
	_theme_name = theme_name
	board.board_theme = BoardTheme.create(theme_name)
	environment.apply_preset(theme_name)
	if _biome_label:
		_biome_label.text = _biome_subtitle(theme_name)
	for key in _theme_buttons:
		_theme_buttons[key].set_pressed_no_signal(key == theme_name)


func _biome_subtitle(theme_name: StringName) -> String:
	match theme_name:
		&"paramo":
			return "Nivel 1 · Páramo de Sumapaz"
		&"amazonia":
			return "Nivel 2 · Selva Amazónica"
		&"santuario":
			return "Nivel 3 · Santuario en crisis"
	return "Tablero clásico"


func _build_ui() -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.06, 0.8)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(22)
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 6)
	_panel.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)

	box.add_child(_label("AJEDREZ SALVAJE", 28, CREAM))
	_biome_label = _label(_biome_subtitle(_theme_name), 15, Color("#d4b45a"))
	box.add_child(_biome_label)
	box.add_child(_separator())

	box.add_child(_label("BIOMA", 12, MUTED))
	var themes := HBoxContainer.new()
	themes.add_theme_constant_override("separation", 6)
	var group := ButtonGroup.new()
	for i in BoardTheme.PRESETS.size():
		var preset: StringName = BoardTheme.PRESETS[i]
		var button := _button(BoardTheme.create(preset).display_name)
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = "Tecla %d" % (i + 1)
		button.pressed.connect(_set_theme.bind(preset))
		themes.add_child(button)
		_theme_buttons[preset] = button
	box.add_child(themes)

	box.add_child(_label("ACCIONES", 12, MUTED))
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	for entry in [["Cazador", _hunter_step, "Espacio"], ["Catástrofe", _random_catastrophe, "C"],
			["Vista panorámica", _toggle_panorama, "V"], ["Reiniciar", _reset, "R"]]:
		var button := _button(entry[0])
		button.tooltip_text = "Tecla " + entry[2]
		button.pressed.connect(entry[1])
		actions.add_child(button)
	box.add_child(actions)
	if ResourceLoader.exists(MENU_SCENE):
		var menu := _button("Menú principal")
		menu.tooltip_text = "Tecla Esc"
		menu.pressed.connect(_go_to_menu)
		box.add_child(menu)
	box.add_child(_separator())

	_square_label = _label("—", 22, CREAM)
	box.add_child(_square_label)
	_detail_label = _label("", 14, MUTED)
	box.add_child(_detail_label)
	box.add_child(_separator())

	box.add_child(_label("EVENTOS DEL TABLERO", 12, MUTED))
	_events_label = _label("", 13, Color(CREAM, 0.85))
	_events_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_events_label)

	box.add_child(_label("Clic der.: bloquear · Q/E: girar · Rueda: zoom · V: panorámica · Esc: menú\nFichas de relleno: las piezas reales son del módulo de piezas.", 11, MUTED))
	_set_theme(_theme_name)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Con ancho fijo desde el inicio, el salto de línea no infla la altura del panel.
	label.custom_minimum_size.x = PANEL_WIDTH - 44.0
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _separator() -> HSeparator:
	var separator := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color(1, 1, 1, 0.1)
	separator.add_theme_stylebox_override("separator", line)
	return separator


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	var states := {
		"normal": Color(1, 1, 1, 0.06), "hover": Color(1, 1, 1, 0.14),
		"pressed": Color("#d4b45a"), "hover_pressed": Color("#e0c46c"),
	}
	for state in states:
		var box := StyleBoxFlat.new()
		box.bg_color = states[state]
		box.set_corner_radius_all(8)
		box.content_margin_top = 7
		box.content_margin_bottom = 7
		box.content_margin_left = 6
		box.content_margin_right = 6
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#1d1a14"))
	button.add_theme_color_override("font_hover_pressed_color", Color("#1d1a14"))
	return button


func _update_info() -> void:
	if _square_label == null:
		return
	var focus := _hovered if _hovered != Board.INVALID else _selected
	if focus == Board.INVALID:
		_square_label.text = "Pasa el cursor por el tablero"
		_detail_label.text = "%d fichas en juego · %d casillas bloqueadas" % [
				board.get_all_pieces().size(), board.get_blocked_coords().size()]
		return
	var piece = board.get_piece_at(focus)
	_square_label.text = "Casilla %s" % Board.coord_to_algebraic(focus).to_upper()
	var lines: PackedStringArray = []
	lines.append(_describe(piece) if piece else "Vacía")
	lines.append("Casilla %s%s" % ["clara" if Board.is_light_square(focus) else "oscura",
			" · intransitable" if board.is_blocked(focus) else ""])
	if _hunter:
		lines.append("Distancia Manhattan al cazador: %d" % Board.manhattan_distance(focus, board.find_piece(_hunter)))
	_detail_label.text = "\n".join(lines)


## Escena fija para capturas de pantalla (argumento --demo-shot).
func _play_screenshot_scene() -> void:
	var saved := board.move_duration
	board.move_duration = 0.0
	var sq := Board.algebraic_to_coord
	board.move_piece(sq.call("d4"), sq.call("e4")) # cazador
	_move(sq.call("e2"), sq.call("e3"))
	_move(sq.call("d7"), sq.call("d6"))
	board.move_piece(sq.call("b1"), sq.call("d7")) # venado junto al rey rival -> jaque
	_move(sq.call("d6"), sq.call("d5"))
	_move(sq.call("d5"), sq.call("d4"))
	board.set_blocked(sq.call("c5"))
	board.set_blocked(sq.call("g4"))
	_select(sq.call("e3"))
	board.move_duration = saved
	_hovered = sq.call("e4")
	board.get_cell(_hovered).hovered = true
	_update_info()
