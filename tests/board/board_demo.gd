extends Node3D
## Demo jugable del tablero 3D con las reglas de ajedrez y el HUD de partida.
##
## Abrir tests/board/board_demo.tscn en el editor de Godot y ejecutar la escena
## actual: F6 en Windows/Linux, Cmd+R en macOS. Desde la terminal:
##   godot --path . res://tests/board/board_demo.tscn
## Opciones: -- --theme=amazonia  --fen="..."  --no-intro
##
## Se juega ajedrez FIDE completo con las piezas del juego. Lo provisional:
## - El rival automático captura lo de más valor; la IA real (agentes ABM)
##   es del módulo de simulación.
## - El cazador se mueve con un botón o con Espacio, con azar simple; la
##   caminata real (generador de Lehmer) y las fases del turno son de los
##   módulos de simulación e integración.
## - Agua, clima y vivero se muestran como "pendiente" en el HUD hasta que el
##   módulo de simulación los calcule.

const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")

const PIECE_SCALE := 1.3
const TRAY_SCALE := 0.62
## Brillo del filete del marco según quién mueve.
const GLOW_PLAYER := Color("#fff1d2")
const GLOW_RIVAL := Color("#ffae4a")
const GLOW_CHECK := Color("#ff5a40")
const RIVAL_DELAY := 0.75
## Valor de las piezas (material) para el rival provisional y la ventaja.
const VALUES := {1: 1, 2: 3, 3: 3, 4: 5, 5: 9, 6: 0, 16: 0}
## Datos de cada nivel (documento, sección 4.3).
const LEVELS := {
	&"paramo": [1, "Páramo en Alerta", "Reserva de Sumapaz", "Objetivo: jaque mate, o resistir 15 turnos con agua > 30%."],
	&"amazonia": [2, "Frente de Deforestación", "Selva Amazónica", "Objetivo: jaque mate con más de 4 plantas vivas."],
	&"santuario": [3, "Colapso Antrópico", "Santuario mixto en crisis", "Objetivo: desarticular al rival con agua > 60%."],
	&"clasico": [0, "Tablero clásico", "Ajedrez sin bioma", ""],
}

## Bioma con el que arranca la demo (lo asigna el menú principal).
@export var initial_theme: StringName = &""

@onready var board: Board = $Board
@onready var camera: Camera3D = $Camera3D
@onready var environment: Node3D = $Environment
@onready var ui_layer: CanvasLayer = $UI

var hud: GameHUD
var _match: ChessMatch
var _selected := Board.INVALID
var _hovered := Board.INVALID
var _last_move: Array[Vector2i] = []
var _hunter: ChessPiece
var _theme_name: StringName = &"paramo"
var _rng := RandomNumberGenerator.new()
var _auto_rival := true
var _game_over := false
var _game_token := 0
## Piezas capturadas, en miniatura a los lados del tablero (como en un
## ajedrez físico): las del jugador a su derecha, las del rival a la izquierda.
var _tray: Node3D
var _tray_count := [0, 0]
## Posición inicial (se puede cambiar con el argumento --fen="...").
var _start_fen := ChessPosition.START_FEN

# Cámara orbital alrededor del centro del tablero.
const PLAY_VIEW := Vector3(0.0, 52.0, 17.5) # giro, inclinación (grados), distancia
const PANORAMA_VIEW := Vector3(-0.5, 11.0, 30.0)
var _yaw := deg_to_rad(PLAY_VIEW.x)
var _pitch := deg_to_rad(PLAY_VIEW.y)
var _distance := PLAY_VIEW.z
var _orbiting := false
var _panorama := false
var _camera_tween: Tween


func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_rng.randomize()
	hud = HUD_SCENE.instantiate()
	ui_layer.add_child(hud)
	hud.hunter_step_requested.connect(_hunter_step)
	hud.catastrophe_requested.connect(_random_catastrophe)
	hud.view_toggle_requested.connect(_toggle_panorama)
	hud.restart_requested.connect(_reset)
	hud.menu_requested.connect(_go_to_menu)
	hud.auto_rival_toggled.connect(_toggle_auto_rival)
	hud.theme_selected.connect(_set_theme)
	hud.pause_changed.connect(_on_pause_changed)
	board.cell_clicked.connect(_on_cell_clicked)
	board.cell_right_clicked.connect(_on_cell_right_clicked)
	board.cell_hovered.connect(_on_cell_hovered)
	get_viewport().size_changed.connect(_update_camera)
	_tray = Node3D.new()
	_tray.name = "CapturedTray"
	board.add_child(_tray)

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
	_update_camera()
	_reset()
	if args.has("--demo-shot"):
		_play_screenshot_scene()
	elif not args.has("--no-intro"):
		_play_camera_intro()
		hud.play_level_intro(0.8)


func _process(_delta: float) -> void:
	_update_turn_anchor()


## Ubica el indicador de turno sobre el borde del tablero que queda más arriba
## en pantalla (sigue a la cámara cuando gira).
func _update_turn_anchor() -> void:
	var bounds := board.get_bounds()
	var top := bounds.end.y + 0.05
	var best := Vector2(0, INF)
	var visible := false
	for edge in [Vector3(0, top, bounds.position.z), Vector3(0, top, bounds.end.z),
			Vector3(bounds.position.x, top, 0), Vector3(bounds.end.x, top, 0)]:
		var world := board.to_global(edge)
		if camera.is_position_behind(world):
			continue
		var screen := camera.unproject_position(world)
		if screen.y < best.y:
			best = screen
			visible = true
	hud.set_turn_anchor(best, visible)


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_paused():
		return
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
	var target := Vector3(0.0, -0.2, 0.35)
	camera.position = target + offset
	camera.look_at(target, Vector3.UP)


## Vuelve al menú principal (si existe en el proyecto).
func _go_to_menu() -> void:
	if ResourceLoader.exists(MENU_SCENE):
		get_tree().change_scene_to_file(MENU_SCENE)


func _on_pause_changed(paused: bool) -> void:
	board.input_enabled = not paused
	if not paused:
		_schedule_rival()


# ---------------------------------------------------------------------------
# Partida
# ---------------------------------------------------------------------------

func _reset() -> void:
	_game_token += 1
	_game_over = false
	hud.hide_game_over()
	board.clear_blocked()
	_selected = Board.INVALID
	_last_move.clear()
	for piece in _tray.get_children():
		piece.queue_free()
	_tray_count = [0, 0]
	_match = ChessMatch.new(board)
	_match.setup_initial(_start_fen, PIECE_SCALE)
	_hunter = ChessPiece.create(ChessPiece.Kind.HUNTER, ChessPiece.Team.NEUTRAL)
	_hunter.scale = Vector3.ONE * PIECE_SCALE
	if not board.place_piece(_hunter, Board.algebraic_to_coord("d4")):
		_hunter.free()
		_hunter = null
	_match.sync()
	hud.clear_moves()
	hud.set_ecosystem()
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
	_update_hover()


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
		if captured == _hunter:
			_hunter = null
			captured.queue_free()
		else:
			_send_to_tray(captured, move.captured_coord(), mover)
	var status := _match.status()
	if status == MovementValidator.Status.CHECKMATE:
		text += "#"
	elif status == MovementValidator.Status.CHECK:
		text += "+"
	hud.add_move(mover, text)
	_last_move = [move.from_coord(), move.to_coord()]
	_selected = Board.INVALID
	if move.promotion != 0:
		hud.show_banner("¡Coronación! El frailejón se convierte en danta", &"gold")
	_refresh_state()
	_schedule_rival()


## Lleva la pieza capturada, en un salto, a la fila de miniaturas de quien
## la capturó (junto al tablero, sobre el suelo).
func _send_to_tray(piece: ChessPiece, from: Vector2i, capturer: int) -> void:
	var slot: int = _tray_count[capturer]
	_tray_count[capturer] += 1
	var bounds := board.get_bounds()
	var player := capturer == ChessPiece.Team.PLAYER
	var column := slot / 8
	var row := slot % 8
	var x := (bounds.end.x + 0.5 + column * 0.6) if player else (bounds.position.x - 0.5 - column * 0.6)
	var z := (3.5 - row) * 0.85 if player else (row - 3.5) * 0.85
	var target := Vector3(x, bounds.position.y, z)
	var start := board.coord_to_position(from)
	var base: Vector3 = piece.get_meta(&"board_base_scale", piece.scale)
	_tray.add_child(piece)
	piece.position = start
	var hop := func(t: float) -> void:
		piece.position = start.lerp(target, t) + Vector3.UP * sin(t * PI) * 1.4
	var tween := piece.create_tween()
	tween.tween_method(hop, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(piece, "scale", base * TRAY_SCALE, 0.7)


func _schedule_rival() -> void:
	if _game_over or not _auto_rival or hud.is_paused() or _match.side_to_move() != ChessPiece.Team.RIVAL:
		return
	var token := _game_token
	await get_tree().create_timer(RIVAL_DELAY).timeout
	if token == _game_token and not _game_over and _auto_rival and not hud.is_paused() \
			and _match.side_to_move() == ChessPiece.Team.RIVAL:
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
		var score: float = float(VALUES.get(ChessPosition.kind_of(move.captured), 0)) + _rng.randf() * 0.6
		if move.promotion == MovementValidator.QUEEN:
			score += 8.0
		if score > best_score:
			best_score = score
			best = move
	_play(best)


func _hunter_step() -> void:
	if _game_over or hud.is_paused():
		return
	if _hunter == null or board.find_piece(_hunter) == Board.INVALID:
		hud.show_banner("El cazador ya no está en el tablero")
		return
	var from := board.find_piece(_hunter)
	var options := Board.get_orthogonal_neighbors(from)
	var to: Vector2i = options[_rng.randi() % options.size()]
	var victim := board.get_piece_at(to) as ChessPiece
	if victim:
		hud.show_banner("¡El cazador acabó con %s en %s!" % [victim.display_name(), Board.coord_to_algebraic(to)], &"alert")
		board.destroy_piece(to)
	board.move_piece(from, to)
	_last_move = [from, to]
	_after_board_change()


func _random_catastrophe() -> void:
	if _game_over or hud.is_paused():
		return
	var candidates := board.get_empty_coords().filter(func(c: Vector2i) -> bool: return not board.is_blocked(c))
	if candidates.is_empty():
		return
	var target: Vector2i = candidates[_rng.randi() % candidates.size()]
	board.set_blocked(target)
	hud.show_banner("Catástrofe en %s: la casilla queda intransitable" % Board.coord_to_algebraic(target), &"alert")
	_after_board_change()


## Tras un cambio externo (cazador, catástrofe) las reglas releen el tablero.
func _after_board_change() -> void:
	_match.sync()
	_selected = Board.INVALID
	_refresh_state()
	_schedule_rival()


## Redibuja resaltados (última jugada, jaque) y actualiza el HUD.
func _refresh_state() -> void:
	board.clear_highlights()
	board.highlight_cells(_last_move, Cell.Highlight.LAST_MOVE)
	var status := _match.status()
	var side := _match.side_to_move()
	var in_check := status == MovementValidator.Status.CHECK or status == MovementValidator.Status.CHECKMATE
	if in_check:
		var king := _match.position.find_king(side)
		if king >= 0:
			board.set_highlight(ChessPosition.to_coord(king), Cell.Highlight.CHECK)
	hud.set_turn(side, _match.position.fullmove_number, in_check)
	board.set_frame_glow(GLOW_CHECK if in_check else (GLOW_PLAYER if side == ChessPiece.Team.PLAYER else GLOW_RIVAL),
			2.2 if in_check else 1.3)
	if status == MovementValidator.Status.CHECK and not _game_over and _selected == Board.INVALID:
		hud.show_banner("¡Jaque! Protege a tu rey" if side == ChessPiece.Team.PLAYER else "¡Jaque al rey rival!", &"alert")
	if not _game_over:
		match status:
			MovementValidator.Status.CHECKMATE:
				_finish(&"victory" if side == ChessPiece.Team.RIVAL else &"defeat", "Jaque mate")
			MovementValidator.Status.STALEMATE:
				_finish(&"draw", "Ahogado: ningún bando puede mover")
			MovementValidator.Status.KING_LOST:
				_finish(&"victory" if _match.winner() == ChessPiece.Team.PLAYER else &"defeat", "El cazador acabó con un rey")
	_update_hover()


func _finish(result: StringName, reason: String) -> void:
	_game_over = true
	var title := "¡Victoria!" if result == &"victory" else ("Derrota" if result == &"defeat" else "Tablas")
	var level: Array = LEVELS.get(_theme_name, LEVELS[&"paramo"])
	var subtitle := "%s · %s\n%d jugadas" % [reason, level[1], _match.position.fullmove_number]
	hud.show_game_over(title, subtitle, result)
	hud.set_turn_message(reason if reason.length() < 24 else title)
	board.set_frame_glow(Color("#ffd75e") if result == &"victory" else GLOW_CHECK, 1.6)


func _toggle_auto_rival(enabled: bool) -> void:
	_auto_rival = enabled
	_selected = Board.INVALID
	_refresh_state()
	_schedule_rival()


func _update_hover() -> void:
	if hud == null:
		return
	if _hovered == Board.INVALID:
		hud.set_hover_info("")
		return
	var text := Board.coord_to_algebraic(_hovered).to_upper()
	var piece := board.get_piece_at(_hovered) as ChessPiece
	if piece:
		text += "  ·  " + piece.display_name()
		if piece.kind != ChessPiece.Kind.HUNTER:
			text += " · %s" % ChessPiece.CHESS_NAMES.get(piece.kind, "")
	elif board.is_blocked(_hovered):
		text += "  ·  intransitable"
	else:
		text += "  ·  vacía"
	if _hunter and board.find_piece(_hunter) != Board.INVALID and piece != _hunter:
		var distance := Board.manhattan_distance(_hovered, board.find_piece(_hunter))
		text += "  ·  a %d %s del cazador" % [distance, "casilla" if distance == 1 else "casillas"]
	hud.set_hover_info(text)


func _set_theme(theme_name: StringName) -> void:
	if not theme_name in BoardTheme.PRESETS:
		theme_name = &"paramo"
	_theme_name = theme_name
	board.board_theme = BoardTheme.create(theme_name)
	environment.apply_preset(theme_name)
	hud.apply_board_theme(board.board_theme)
	var level: Array = LEVELS[theme_name]
	hud.set_level(level[0], level[1], level[2], level[3])
	hud.set_theme_name(theme_name)
	if hud.is_paused():
		hud.set_paused(false)
		hud.play_level_intro(0.3)


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
	_update_hover()
