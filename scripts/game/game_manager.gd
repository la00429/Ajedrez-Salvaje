class_name GameManager
extends Node3D
## Controlador principal de la partida jugable de Ajedrez Salvaje (Rol 5).
##
## Integra:
## - Tablero 3D ([Board]) y Piezas ([ChessPiece])
## - Reglas de ajedrez FIDE completas ([ChessMatch])
## - Motor de simulación estocástica ([SimulationEngine])
## - Interfaz gráfica diegética ([GameHUD])
##
## Dos jugadores en el mismo equipo (hotseat local):
## - Jugador 1 (Guardián / Blancas, fila 1 y 2)
## - Jugador 2 (Rival / Negras, fila 7 y 8)
## Al cambiar de turno, el tablero gira 180° hacia el jugador activo.
## Cada ronda ejecuta la fase ambiental (clima, dinámica hídrica, vivero M/M/1,
## cazador furtivo y retroexcavadora).

const MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const HUD_SCENE := preload("res://scenes/ui/GameHUD.tscn")

const PIECE_SCALE := 1.3
const TRAY_SCALE := 0.62

const GLOW_PLAYER := Color("#fff1d2")
const GLOW_RIVAL := Color("#ffae4a")
const GLOW_CHECK := Color("#ff5a40")

const PLAY_VIEW := Vector3(0.0, 52.0, 17.5) # yaw, pitch (deg), dist
const PANORAMA_VIEW := Vector3(-0.5, 11.0, 30.0)

const LEVELS := {
	&"paramo": [1, "Páramo en Alerta", "Reserva de Sumapaz", "Jaque mate, o resistir 15 turnos con agua > 30%."],
	&"amazonia": [2, "Frente de Deforestación", "Selva Amazónica", "Jaque mate con más de 4 plantas vivas."],
	&"santuario": [3, "Colapso Antrópico", "Santuario mixto en crisis", "Desarticular al rival con agua > 60%."],
	&"clasico": [0, "Tablero clásico", "Ajedrez sin bioma", ""],
}

@export var initial_theme: StringName = &"paramo"

@onready var board: Board = $Board
@onready var camera: Camera3D = $Camera3D
@onready var environment: Node3D = $Environment
@onready var ui_layer: CanvasLayer = $UI
@onready var _audio: AudioManagerService = get_node("/root/AudioManager")

var hud: GameHUD
var _match: ChessMatch
var _engine: SimulationEngine
var _config: SimulationConfig

var _round_number := 1
var _level_number := 1
var _selected := Board.INVALID
var _hovered := Board.INVALID
var _last_move: Array[Vector2i] = []
var _game_over := false

var _hunter_piece: ChessPiece
var _excavator_piece: ChessPiece
var _tray: Node3D
var _tray_count: Array[int] = [0, 0]
var _theme_name: StringName = &"paramo"
var _current_climate_str: String = "Estable"

var _yaw := deg_to_rad(PLAY_VIEW.x)
var _pitch := deg_to_rad(PLAY_VIEW.y)
var _distance := PLAY_VIEW.z
var _orbiting := false
var _panorama := false
var _camera_tween: Tween


func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_4X
	camera.fov = 40.0
	
	hud = HUD_SCENE.instantiate()
	ui_layer.add_child(hud)
	
	hud.restart_requested.connect(_reset)
	hud.menu_requested.connect(_go_to_menu)
	hud.view_toggle_requested.connect(_toggle_panorama)
	hud.pause_changed.connect(_on_pause_changed)
	hud.theme_selected.connect(_set_theme)
	hud.hunter_step_requested.connect(_manual_hunter_step)
	hud.catastrophe_requested.connect(_manual_catastrophe)
	
	board.cell_clicked.connect(_on_cell_clicked)
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
		elif arg.begins_with("--level="):
			_level_number = arg.trim_prefix("--level=").to_int()
			
	_set_theme(_theme_name)
	_update_camera()
	_setup_game()
	
	if not args.has("--no-intro"):
		_play_camera_intro()
		hud.play_level_intro(0.8)


func _process(_delta: float) -> void:
	_update_turn_anchor()


## Inicia la partida configurada desde el menú principal para un nivel dado.
func start_level(level_index: int) -> void:
	_level_number = level_index
	match level_index:
		1:
			_theme_name = &"paramo"
			_round_number = 1
		2:
			_theme_name = &"amazonia"
			_round_number = 11
		3:
			_theme_name = &"santuario"
			_round_number = 21
		_:
			_theme_name = &"paramo"
			_round_number = 1
	_set_theme(_theme_name)
	_setup_game()
	hud.play_level_intro(0.4)


func _setup_game() -> void:
	_game_over = false
	_selected = Board.INVALID
	_last_move.clear()
	board.clear_blocked()
	board.clear_highlights()
	_clear_tray()
	if hud:
		hud.hide_game_over()
		hud.clear_moves()
	
	_config = SimulationConfig.new()
	_engine = SimulationEngine.new(_config)
	
	_match = ChessMatch.new(board)
	_match.setup_initial(ChessPosition.START_FEN, PIECE_SCALE)
	_audio.play_event(&"game_start")
	
	# Colocar cazador neutral en la posición inicial (d4)
	_hunter_piece = ChessPiece.create(ChessPiece.Kind.HUNTER, ChessPiece.Team.NEUTRAL)
	_hunter_piece.scale = Vector3.ONE * PIECE_SCALE
	board.place_piece(_hunter_piece, _engine.hunter)
	_excavator_piece = null
	
	_start_round(_round_number)


func _start_round(round_num: int) -> void:
	_round_number = round_num
	
	# Ejecutar fase ambiental de simulación
	var result := _engine.run_round(_round_number, _match.position)
	_apply_environment(result)
	_match.sync()
	
	_update_hud_round(result)
	
	# Evaluar fin de partida tras fase ambiental
	if _check_victory():
		return
		
	# Iniciar el turno del jugador activo (blancas al iniciar ronda)
	_begin_turn(_match.side_to_move())


func _apply_environment(result: RoundResult) -> void:
	# 1. Regeneración de plantas en vivero M/M/1
	for side in [ChessPosition.PLAYER, ChessPosition.RIVAL]:
		var entity: QueueEntity = result.regenerated[side]
		if entity != null:
			var target_row := 1 if side == ChessPosition.PLAYER else 6
			var empty_coord := board.first_empty_in_row(target_row)
			if empty_coord != Board.INVALID:
				var pawn := ChessPiece.create(ChessPiece.Kind.PAWN, side as ChessPiece.Team)
				pawn.scale = Vector3.ONE * PIECE_SCALE
				board.place_piece(pawn, empty_coord)
				board.spawn_effect(empty_coord, Color(0.2, 0.95, 0.4))
				hud.show_banner("¡Frailejón regenerado en %s!" % board.coord_to_algebraic(empty_coord), &"good")
				_audio.play_simulation(&"regeneration")
			else:
				# Si la fila base está ocupada, reencolar en el vivero
				_engine.enqueue_capture(side, entity.payload, _round_number)
				
	# 2. Desplazamiento del cazador (Agente ABM)
	if result.hunter != null and result.hunter.step.has_moved():
		var from_coord := result.hunter.step.from
		var to_coord := result.hunter.step.to
		if board.is_occupied(to_coord):
			var victim := board.get_piece_at(to_coord) as ChessPiece
			if victim != null and victim != _hunter_piece:
				_audio.play_fauna_call(_theme_name)
				if victim.kind == ChessPiece.Kind.PAWN:
					_engine.enqueue_capture(victim.side, victim, _round_number)
				_send_to_tray(victim, to_coord, 2)
				board.remove_piece(to_coord)
				hud.show_banner("Cazador taló en %s" % board.coord_to_algebraic(to_coord), &"bad")
		board.move_piece(from_coord, to_coord)
		
	# 3. Retroexcavadora (Caminata aleatoria 2D en nivel 3)
	if result.excavator_spawned:
		_excavator_piece = ChessPiece.create(ChessPiece.Kind.EXCAVATOR, ChessPiece.Team.NEUTRAL)
		_excavator_piece.scale = Vector3.ONE * PIECE_SCALE
		board.place_piece(_excavator_piece, result.excavator.from)
		hud.show_banner("¡Retroexcavadora entró al bioma!", &"bad")
		
	if result.excavator != null and result.excavator.has_moved():
		var from_coord := result.excavator.from
		var to_coord := result.excavator.to
		if board.is_occupied(to_coord):
			var victim := board.get_piece_at(to_coord) as ChessPiece
			if victim != null and victim != _excavator_piece and victim != _hunter_piece:
				if victim.kind == ChessPiece.Kind.PAWN:
					_engine.enqueue_capture(victim.side, victim, _round_number)
				_send_to_tray(victim, to_coord, 3)
				board.remove_piece(to_coord)
				hud.show_banner("Retroexcavadora destruyó en %s" % board.coord_to_algebraic(to_coord), &"bad")
		board.move_piece(from_coord, to_coord)
		
	# 4. Tala de casillas que quedan intransitables
	if result.felled != Board.INVALID:
		board.set_blocked(result.felled, true)
		hud.show_banner("Casilla %s bloqueada por tala" % board.coord_to_algebraic(result.felled), &"bad")


func _begin_turn(side: int) -> void:
	# El tablero gira 180° hacia el lado del jugador activo
	board.orient_to_side(side)
	board.input_enabled = true
	_selected = Board.INVALID
	_refresh_state()
	
	var in_check := _match.is_in_check(side)
	var side_name := "Jugador 1 (Guardián)" if side == ChessPosition.PLAYER else "Jugador 2 (Rival)"
	hud.set_turn(side, _round_number, in_check)
	hud.set_turn_message("Turno de %s" % side_name)
	
	if in_check:
		board.set_frame_glow(GLOW_CHECK, 2.0)
		hud.show_banner("¡JAQUE A %s!" % side_name.to_upper(), &"alert")
	elif side == ChessPosition.PLAYER:
		board.set_frame_glow(GLOW_PLAYER, 1.2)
	else:
		board.set_frame_glow(GLOW_RIVAL, 1.2)
		
	_update_hud_ecosystem(side)


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
	if piece and piece.side == _match.side_to_move() and coord != _selected:
		_select(coord)
	else:
		_selected = Board.INVALID
		_refresh_state()


func _select(coord: Vector2i) -> void:
	_selected = coord
	_refresh_state()
	board.set_highlight(coord, Cell.Highlight.SELECTED)
	for move in _match.legal_moves_from(coord):
		board.set_highlight(move.to_coord(), Cell.Highlight.CAPTURE if move.is_capture() else Cell.Highlight.MOVE)


func _play(move: ChessMove) -> void:
	board.input_enabled = false
	var mover := _match.side_to_move()
	var captured := _match.play(move)
	_audio.play_event(&"piece_capture" if captured != null else &"piece_move")
	var text := move.notation()
	
	if captured:
		if captured == _hunter_piece:
			_hunter_piece = null
			captured.queue_free()
		elif captured == _excavator_piece:
			_excavator_piece = null
			captured.queue_free()
		elif captured.kind == ChessPiece.Kind.PAWN:
			_engine.enqueue_capture(captured.side, captured, _round_number)
			_send_to_tray(captured, move.captured_coord(), mover)
		else:
			_send_to_tray(captured, move.captured_coord(), mover)
			
	var status := _match.status()
	if status == MovementValidator.Status.CHECKMATE:
		text += "#"
	elif status == MovementValidator.Status.CHECK:
		text += "+"
		_audio.play_event(&"king_threatened")
	hud.add_move(mover, text)
	
	_last_move = [move.from_coord(), move.to_coord()]
	_selected = Board.INVALID
	_refresh_state()
	
	# Verificar fin de partida tras el movimiento
	if _check_victory():
		return
		
	# Siguiente turno: si vuelve a PLAYER, se completó la ronda de ambos!
	if _match.side_to_move() == ChessPosition.PLAYER:
		_round_number += 1
		_start_round(_round_number)
	else:
		_begin_turn(ChessPosition.RIVAL)


func _check_victory() -> bool:
	var verdict := _engine.verdict(_match.position, _round_number)
	if not verdict.is_finished():
		return false
		
	_game_over = true
	board.input_enabled = false
	
	var title := ""
	var subtitle := ""
	var result_kind := &"draw"
	
	match verdict.reason:
		Verdict.Reason.CHECKMATE:
			var winner_name := "Jugador 1" if verdict.winner == 0 else "Jugador 2"
			title = "¡JAQUE MATE!"
			subtitle = "Victoria de %s por maestría táctica FIDE." % winner_name
			result_kind = &"victory" if verdict.winner == 0 else &"defeat"
		Verdict.Reason.KING_LOST:
			var loser_name := "Jugador 2" if verdict.winner == 0 else "Jugador 1"
			title = "¡REY DESTRUIDO!"
			subtitle = "El Gran Abuelo de %s cayó víctima de desestabilizadores." % loser_name
			result_kind = &"victory" if verdict.winner == 0 else &"defeat"
		Verdict.Reason.WATER_COLLAPSE:
			var collapsed_name := "Jugador 2" if verdict.winner == 0 else "Jugador 1"
			var winner_name := "Jugador 1" if verdict.winner == 0 else "Jugador 2"
			title = "¡COLAPSO HÍDRICO!"
			subtitle = "El bioma de %s colapsó por sequía (0%% agua). Gana %s." % [collapsed_name, winner_name]
			result_kind = &"victory" if verdict.winner == 0 else &"defeat"
		Verdict.Reason.BOTH_COLLAPSED:
			title = "DESERTIFICACIÓN TOTAL"
			subtitle = "Ambos ecosistemas colapsaron en la misma ronda. Tablas ambientales."
			result_kind = &"draw"
		Verdict.Reason.FINAL_WATER:
			var winner_name := "Jugador 1" if verdict.winner == 0 else "Jugador 2"
			title = "RONDA FINAL 30 ALCANZADA"
			subtitle = "Victoria para %s por conservar mayor reserva hídrica." % winner_name
			result_kind = &"victory" if verdict.winner == 0 else &"defeat"
		Verdict.Reason.FINAL_MATERIAL:
			var winner_name := "Jugador 1" if verdict.winner == 0 else "Jugador 2"
			title = "RONDA FINAL 30 ALCANZADA"
			subtitle = "Empate hídrico. Gana %s por mayor material en tablero." % winner_name
			result_kind = &"victory" if verdict.winner == 0 else &"defeat"
		Verdict.Reason.FINAL_DRAW:
			title = "TABLAS DEFINITIVAS"
			subtitle = "Empate absoluto en agua y material al término de la ronda 30."
			result_kind = &"draw"
		Verdict.Reason.STALEMATE:
			title = "¡REY AHOGADO!"
			subtitle = "Tablas reglamentarias según el reglamento oficial FIDE."
			result_kind = &"draw"
			
	if verdict.reason == Verdict.Reason.WATER_COLLAPSE or verdict.reason == Verdict.Reason.BOTH_COLLAPSED:
		_audio.play_simulation(&"collapse")
	if result_kind == &"victory":
		_audio.play_event(&"victory")
	elif result_kind == &"defeat":
		_audio.play_event(&"defeat")
	_audio.stop_simulation_audio()
	hud.show_game_over(title, subtitle, result_kind)
	hud.set_turn_message(title)
	board.set_frame_glow(Color("#ffd75e") if result_kind == &"victory" else GLOW_CHECK, 1.8)
	return true


func _update_hud_round(result: RoundResult) -> void:
	var level_data: Array = LEVELS.get(_theme_name, LEVELS[&"paramo"])
	hud.set_level(result.level, level_data[1], level_data[2], level_data[3])
	if result.level_started:
		hud.play_level_intro(0.3)
		hud.show_banner("¡NIVEL %d: %s!" % [result.level, result.climate_label().to_upper()], &"info")
		
	_current_climate_str = result.climate_label()
	var climate_name: StringName
	match result.climate:
		Climate.Type.RAIN:
			climate_name = &"rain"
		Climate.Type.FROST:
			climate_name = &"frost"
		Climate.Type.CATASTROPHE:
			climate_name = &"catastrophe"
		_:
			climate_name = &"stable"
	var lowest_water := minf(_engine.water(ChessPosition.PLAYER), _engine.water(ChessPosition.RIVAL))
	_audio.update_simulation_state(
			_theme_name, climate_name, lowest_water, _engine.excavator != Board.INVALID)
	_update_hud_ecosystem(_match.side_to_move())


func _update_hud_ecosystem(side: int) -> void:
	var water_pct := _engine.water(side)
	var queue_len := _engine.nursery(side).queue.length()
	hud.set_ecosystem(water_pct, _current_climate_str, queue_len)


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
	_update_hover()


func _on_cell_hovered(coord: Vector2i) -> void:
	_hovered = coord
	_update_hover()


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
		if piece.kind != ChessPiece.Kind.HUNTER and piece.kind != ChessPiece.Kind.EXCAVATOR:
			text += " · %s" % ChessPiece.CHESS_NAMES.get(piece.kind, "")
	elif board.is_blocked(_hovered):
		text += "  ·  bloqueada (talada)"
	else:
		text += "  ·  vacía"
		
	if _hunter_piece and board.find_piece(_hunter_piece) != Board.INVALID and piece != _hunter_piece:
		var dist := Board.manhattan_distance(_hovered, board.find_piece(_hunter_piece))
		text += "  ·  a %d %s del cazador" % [dist, "casilla" if dist == 1 else "casillas"]
	hud.set_hover_info(text)


func _send_to_tray(piece: ChessPiece, board_coord: Vector2i, taker_side: int) -> void:
	var side_index := 0 if taker_side == ChessPosition.PLAYER else 1
	var slot: int = _tray_count[side_index]
	_tray_count[side_index] += 1
	
	piece.reparent(_tray)
	piece.rotation = Vector3.ZERO
	
	var col: int = slot % 2
	var row: int = slot / 2
	var x_offset: float = (4.9 + float(col) * 0.7) * (1.0 if side_index == 0 else -1.0)
	var z_offset: float = -3.2 + float(row) * 0.75
	var target_pos := Vector3(x_offset, 0.05, z_offset)
	
	var start_pos := board.coord_to_position(board_coord) + Vector3(0, 0.4, 0)
	piece.position = start_pos
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(piece, "scale", Vector3.ONE * TRAY_SCALE, 0.45)
	tween.tween_property(piece, "position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _clear_tray() -> void:
	_tray_count = [0, 0]
	if _tray:
		for child in _tray.get_children():
			child.queue_free()


func _set_theme(theme_name: StringName) -> void:
	if not theme_name in BoardTheme.PRESETS:
		theme_name = &"paramo"
	_theme_name = theme_name
	board.board_theme = BoardTheme.create(theme_name)
	environment.apply_preset(theme_name)
	_audio.set_biome(theme_name, true)
	hud.apply_board_theme(board.board_theme)
	var level: Array = LEVELS.get(theme_name, LEVELS[&"paramo"])
	hud.set_level(level[0], level[1], level[2], level[3])
	hud.set_theme_name(theme_name)


func _reset() -> void:
	match _level_number:
		1:
			_round_number = 1
		2:
			_round_number = 11
		3:
			_round_number = 21
		_:
			_round_number = 1
	_setup_game()


func _go_to_menu() -> void:
	_audio.stop_simulation_audio()
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_pause_changed(paused: bool) -> void:
	board.input_enabled = not paused and not _game_over


func _toggle_panorama() -> void:
	_panorama = not _panorama
	var view: Vector3 = PANORAMA_VIEW if _panorama else PLAY_VIEW
	_fly_to(Vector3(view.x if _panorama else rad_to_deg(_yaw), view.y, view.z), 1.2)


func _play_camera_intro() -> void:
	_yaw = deg_to_rad(-38.0)
	_pitch = deg_to_rad(9.0)
	_distance = 36.0
	_update_camera()
	_fly_to(PLAY_VIEW, 2.5)


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
	_pitch = clampf(_pitch, deg_to_rad(8.0), deg_to_rad(85.0))
	_distance = clampf(_distance, 8.0, 42.0)
	var center := Vector3.ZERO
	var offset := Vector3(
		_distance * cos(_pitch) * sin(_yaw),
		_distance * sin(_pitch),
		_distance * cos(_pitch) * cos(_yaw)
	)
	camera.position = center + offset
	camera.look_at(center, Vector3.UP)


func _update_turn_anchor() -> void:
	if hud == null:
		return
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			_toggle_panorama()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_TAB:
			hud.toggle_moves()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F1:
			hud.toggle_debug()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(-0.8)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(0.8)
			MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
				_orbiting = event.pressed
	elif event is InputEventMouseMotion and _orbiting:
		_yaw -= event.relative.x * 0.007
		_pitch += event.relative.y * 0.007
		_update_camera()


func _zoom(delta: float) -> void:
	_distance += delta
	_update_camera()


func _manual_hunter_step() -> void:
	if _engine and not _game_over:
		var result := _engine.run_round(_round_number, _match.position)
		_apply_environment(result)
		_match.sync()
		_update_hud_round(result)


func _manual_catastrophe() -> void:
	if _engine and not _game_over:
		hud.show_banner("¡Alerta: Evento extremo en el páramo!", &"bad")
		board.spawn_effect(Vector2i(3, 3), Color(1.0, 0.2, 0.2))
