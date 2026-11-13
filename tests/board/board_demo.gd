extends Node3D
## Demo jugable del tablero 3D con las reglas de ajedrez.
##
## Abrir tests/board/board_demo.tscn en el editor de Godot y ejecutar la escena
## actual: F6 en Windows/Linux, Cmd+R en macOS. Desde la terminal:
##   godot --path . res://tests/board/board_demo.tscn
##
## Se juega ajedrez FIDE completo con las piezas del juego (tablero, piezas y
## reglas). Lo que todavía es provisional:
## - El rival automático elige jugadas con una regla simple (capturar lo de
##   más valor). La IA real (agentes ABM) es del módulo de simulación.
## - El cazador se mueve con el botón o la tecla Espacio, con azar simple; la
##   caminata real (generador de Lehmer) y las fases del turno son de los
##   módulos de simulación e integración.
## - Las piezas capturadas se descartan; el vivero (cola M/M/1) es de simulación.

const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"

const PANEL_WIDTH := 360.0
const MARGIN := 24.0
const MAX_EVENTS := 3
const PIECE_SCALE := 1.3
const RIVAL_DELAY := 0.75
## Valor de las piezas para el rival provisional.
const VALUES := {1: 1.0, 2: 3.0, 3: 3.2, 4: 5.0, 5: 9.0, 6: 100.0, 16: 0.5}

const CREAM := Color("#f1ead8")
const MUTED := Color(0.94, 0.92, 0.85, 0.6)
const GOLD := Color("#d4b45a")
const ALERT := Color("#ff8a6a")

## Bioma con el que arranca la demo (lo asigna el menú principal).
@export var initial_theme: StringName = &""

@onready var board: Board = $Board
@onready var camera: Camera3D = $Camera3D
@onready var environment: Node3D = $Environment
@onready var ui_layer: CanvasLayer = $UI

var _match: ChessMatch
var _selected := Board.INVALID
var _hovered := Board.INVALID
var _last_move: Array[Vector2i] = []
var _hunter: ChessPiece
var _events: PackedStringArray = []
var _theme_name: StringName = &"paramo"
var _rng := RandomNumberGenerator.new()
var _auto_rival := true
var _game_over := false
var _game_token := 0
## Posición inicial (se puede cambiar con el argumento --fen="...").
var _start_fen := ChessPosition.START_FEN

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
var _status_label: Label
var _square_label: Label
var _detail_label: Label
var _events_label: Label
var _theme_buttons: Dictionary = {}
var _rival_button: Button


func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_rng.randomize()
	_build_ui()
	board.cell_clicked.connect(_on_cell_clicked)
	board.cell_right_clicked.connect(_on_cell_right_clicked)
	board.cell_hovered.connect(_on_cell_hovered)
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
		elif arg.begins_with("--fen="):
			_start_fen = arg.trim_prefix("--fen=")
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
# Partida
# ---------------------------------------------------------------------------

func _reset() -> void:
	_game_token += 1
	_game_over = false
	board.clear_blocked()
	_selected = Board.INVALID
	_last_move.clear()
	_match = ChessMatch.new(board)
	_match.setup_initial(_start_fen, PIECE_SCALE)
	_hunter = ChessPiece.create(ChessPiece.Kind.HUNTER, ChessPiece.Team.NEUTRAL)
	_hunter.scale = Vector3.ONE * PIECE_SCALE
	if not board.place_piece(_hunter, Board.algebraic_to_coord("d4")):
		_hunter.free()
		_hunter = null
	_match.sync()
	_events.clear()
	_log("Partida nueva: juegas con marfil." + (" Cazador en d4." if _hunter else ""))
	_refresh_state()


func _can_control(side: int) -> bool:
	return side == ChessPiece.Team.PLAYER or not _auto_rival


func _on_cell_clicked(coord: Vector2i) -> void:
	if _game_over:
		return
	var highlight := board.get_highlight(coord)
	if _selected != Board.INVALID and (highlight == Cell.Highlight.MOVE or highlight == Cell.Highlight.CAPTURE):
		var move := _match.find_move(_selected, coord)
		if move:
			_play(move)
		return
	var piece := board.get_piece_at(coord) as ChessPiece
	if piece and piece.side == _match.side_to_move() and _can_control(piece.side) and coord != _selected:
		_select(coord)
	else:
		_selected = Board.INVALID
		_refresh_state()


func _on_cell_right_clicked(coord: Vector2i) -> void:
	board.set_blocked(coord, not board.is_blocked(coord))
	_after_board_change()


func _on_cell_hovered(coord: Vector2i) -> void:
	_hovered = coord
	_update_info()


func _select(coord: Vector2i) -> void:
	_selected = coord
	_refresh_state()
	board.set_highlight(coord, Cell.Highlight.SELECTED)
	for move in _match.legal_moves_from(coord):
		board.set_highlight(move.to_coord(), Cell.Highlight.CAPTURE if move.is_capture() else Cell.Highlight.MOVE)


## Ejecuta una jugada legal (las coronaciones son a dama).
func _play(move: ChessMove) -> void:
	var mover := _match.side_to_move()
	var captured := _match.play(move)
	var text := move.notation()
	if captured:
		text += "  (%s capturado)" % captured.species_name()
		if captured == _hunter:
			_hunter = null
		captured.queue_free()
	match _match.status():
		MovementValidator.Status.CHECKMATE:
			text += "#"
		MovementValidator.Status.CHECK:
			text += "+"
	_log("%s: %s" % ["Tú" if mover == ChessPiece.Team.PLAYER else "Rival", text])
	_last_move = [move.from_coord(), move.to_coord()]
	_selected = Board.INVALID
	_refresh_state()
	_schedule_rival()


func _schedule_rival() -> void:
	if _game_over or not _auto_rival or _match.side_to_move() != ChessPiece.Team.RIVAL:
		return
	var token := _game_token
	await get_tree().create_timer(RIVAL_DELAY).timeout
	if token == _game_token and not _game_over and _auto_rival and _match.side_to_move() == ChessPiece.Team.RIVAL:
		_rival_move()


## Rival PROVISIONAL: captura lo de más valor y si no, mueve al azar.
## La IA real (agentes ABM, vecindad de Moore de radio 2) es del integrante 3.
func _rival_move() -> void:
	var moves := _match.legal_moves()
	if moves.is_empty():
		return
	var best: ChessMove = null
	var best_score := -INF
	for move in moves:
		var score: float = VALUES.get(ChessPosition.kind_of(move.captured), 0.0) + _rng.randf() * 0.6
		if move.promotion == MovementValidator.QUEEN:
			score += 8.0
		if score > best_score:
			best_score = score
			best = move
	_play(best)


func _hunter_step() -> void:
	if _game_over:
		return
	if _hunter == null or board.find_piece(_hunter) == Board.INVALID:
		_log("El cazador ya no está en el tablero.")
		return
	var from := board.find_piece(_hunter)
	var options := Board.get_orthogonal_neighbors(from)
	var to: Vector2i = options[_rng.randi() % options.size()]
	var victim := board.get_piece_at(to) as ChessPiece
	if victim:
		_log("¡El cazador destruyó %s en %s!" % [victim.display_name(), Board.coord_to_algebraic(to)])
		board.destroy_piece(to)
	else:
		_log("Cazador: %s → %s" % [Board.coord_to_algebraic(from), Board.coord_to_algebraic(to)])
	board.move_piece(from, to)
	_last_move = [from, to]
	_after_board_change()


func _random_catastrophe() -> void:
	var candidates := board.get_empty_coords().filter(func(c: Vector2i) -> bool: return not board.is_blocked(c))
	if candidates.is_empty():
		return
	board.set_blocked(candidates[_rng.randi() % candidates.size()])
	_after_board_change()


## Tras un cambio externo (cazador, catástrofe) las reglas releen el tablero.
func _after_board_change() -> void:
	_match.sync()
	_selected = Board.INVALID
	_refresh_state()
	_schedule_rival()


## Redibuja resaltados (última jugada, jaque) y el estado de la partida.
func _refresh_state() -> void:
	board.clear_highlights()
	board.highlight_cells(_last_move, Cell.Highlight.LAST_MOVE)
	var status := _match.status()
	var side := _match.side_to_move()
	if status == MovementValidator.Status.CHECK or status == MovementValidator.Status.CHECKMATE:
		var king := _match.position.find_king(side)
		if king >= 0:
			board.set_highlight(ChessPosition.to_coord(king), Cell.Highlight.CHECK)
	var player_turn := side == ChessPiece.Team.PLAYER
	var color := CREAM
	var text := ""
	match status:
		MovementValidator.Status.CHECKMATE:
			_game_over = true
			text = "Jaque mate: ¡ganaste!" if not player_turn else "Jaque mate: gana el rival"
			color = GOLD
		MovementValidator.Status.STALEMATE:
			_game_over = true
			text = "Ahogado: tablas"
			color = GOLD
		MovementValidator.Status.KING_LOST:
			_game_over = true
			var winner := _match.winner()
			text = "El cazador acabó con un rey: %s" % ("¡ganaste!" if winner == ChessPiece.Team.PLAYER else "gana el rival")
			color = GOLD
		MovementValidator.Status.CHECK:
			text = "¡Jaque! Protege a tu rey" if player_turn else "¡Jaque al rey rival!"
			color = ALERT
		_:
			text = "Tu turno (marfil)" if player_turn else "Turno del rival (ébano)…"
	if _game_over:
		text += "  ·  R para reiniciar"
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)
	_update_info()


func _on_cell_blocked_changed(coord: Vector2i, blocked: bool) -> void:
	if blocked:
		_log("Catástrofe en %s: casilla intransitable." % Board.coord_to_algebraic(coord))
	else:
		_log("%s vuelve a ser transitable." % Board.coord_to_algebraic(coord))


func _log(text: String) -> void:
	_events.insert(0, text)
	if _events.size() > MAX_EVENTS:
		_events.resize(MAX_EVENTS)
	if _events_label:
		_events_label.text = "\n".join(_events)


func _toggle_auto_rival(enabled: bool) -> void:
	_auto_rival = enabled
	_selected = Board.INVALID
	_refresh_state()
	_schedule_rival()


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
	style.set_content_margin_all(20)
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

	box.add_child(_label("AJEDREZ SALVAJE", 26, CREAM))
	_biome_label = _label(_biome_subtitle(_theme_name), 14, GOLD)
	box.add_child(_biome_label)
	_status_label = _label("", 18, CREAM)
	box.add_child(_status_label)
	box.add_child(_separator())

	var themes := HBoxContainer.new()
	themes.add_theme_constant_override("separation", 6)
	var group := ButtonGroup.new()
	for i in BoardTheme.PRESETS.size():
		var preset: StringName = BoardTheme.PRESETS[i]
		var button := _button(BoardTheme.create(preset).display_name)
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = "Bioma (tecla %d)" % (i + 1)
		button.pressed.connect(_set_theme.bind(preset))
		themes.add_child(button)
		_theme_buttons[preset] = button
	box.add_child(themes)

	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	for entry in [["Paso del cazador", _hunter_step, "Espacio"], ["Catástrofe", _random_catastrophe, "C"],
			["Vista panorámica", _toggle_panorama, "V"], ["Reiniciar", _reset, "R"]]:
		var button := _button(entry[0])
		button.tooltip_text = "Tecla " + entry[2]
		button.pressed.connect(entry[1])
		actions.add_child(button)
	_rival_button = _button("Rival automático")
	_rival_button.toggle_mode = true
	_rival_button.button_pressed = _auto_rival
	_rival_button.tooltip_text = "Provisional: la IA real (agentes) es del módulo de simulación.\nApagado: mueves ambos bandos."
	_rival_button.toggled.connect(_toggle_auto_rival)
	actions.add_child(_rival_button)
	if ResourceLoader.exists(MENU_SCENE):
		var menu := _button("Menú principal")
		menu.tooltip_text = "Tecla Esc"
		menu.pressed.connect(_go_to_menu)
		actions.add_child(menu)
	box.add_child(actions)
	box.add_child(_separator())

	_square_label = _label("—", 20, CREAM)
	box.add_child(_square_label)
	_detail_label = _label("", 14, MUTED)
	box.add_child(_detail_label)
	box.add_child(_separator())

	box.add_child(_label("JUGADAS Y EVENTOS", 12, MUTED))
	_events_label = _label("", 13, Color(CREAM, 0.85))
	_events_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_events_label)

	box.add_child(_label("Clic der.: bloquear · Q/E: girar · Rueda: zoom · Esc: menú", 11, MUTED))
	_set_theme(_theme_name)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Con ancho fijo desde el inicio, el salto de línea no infla la altura del panel.
	label.custom_minimum_size.x = PANEL_WIDTH - 40.0
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
		"pressed": GOLD, "hover_pressed": Color("#e0c46c"),
	}
	for state in states:
		var box := StyleBoxFlat.new()
		box.bg_color = states[state]
		box.set_corner_radius_all(8)
		box.content_margin_top = 6
		box.content_margin_bottom = 6
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
		_detail_label.text = "%d piezas en juego · %d casillas bloqueadas" % [
				board.get_all_pieces().size(), board.get_blocked_coords().size()]
		return
	var piece := board.get_piece_at(focus) as ChessPiece
	_square_label.text = "Casilla %s" % Board.coord_to_algebraic(focus).to_upper()
	var lines: PackedStringArray = []
	if piece:
		var chess: String = ChessPiece.CHESS_NAMES.get(piece.kind, "")
		lines.append("%s · %s" % [piece.display_name(), chess] if piece.kind != ChessPiece.Kind.HUNTER else piece.display_name())
	else:
		lines.append("Vacía" + (" · intransitable" if board.is_blocked(focus) else ""))
	if _hunter and board.find_piece(_hunter) != Board.INVALID:
		lines.append("Distancia Manhattan al cazador: %d" % Board.manhattan_distance(focus, board.find_piece(_hunter)))
	_detail_label.text = "\n".join(lines)


## Escena fija para capturas: la partida de ejemplo del documento (sección 5),
## con el cazador en su recorrido d4 → c4 → c5 → d5 → e5.
func _play_screenshot_scene() -> void:
	var saved_duration := board.move_duration
	var saved_rival := _auto_rival
	board.move_duration = 0.0
	_auto_rival = false
	var steps := [["hunter", "c4"], ["e2", "e4"], ["e7", "e5"], ["hunter", "c5"], ["g1", "f3"], ["b8", "c6"],
			["hunter", "d5"], ["f1", "c4"], ["d7", "d6"], ["hunter", "e5"], ["d2", "d4"], ["c8", "g4"]]
	for step in steps:
		if step[0] == "hunter":
			var from := board.find_piece(_hunter)
			var to := Board.algebraic_to_coord(step[1])
			if board.is_occupied(to):
				board.destroy_piece(to, false)
			board.move_piece(from, to)
			_match.sync()
		else:
			var move := _match.find_move(Board.algebraic_to_coord(step[0]), Board.algebraic_to_coord(step[1]))
			if move:
				_play(move)
	_auto_rival = saved_rival
	board.move_duration = saved_duration
	_select(Board.algebraic_to_coord("c4"))
	_hovered = Board.algebraic_to_coord("f3")
	board.get_cell(_hovered).hovered = true
	_update_info()
