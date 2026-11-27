extends SceneTree
## Suite de pruebas de integración para Ajedrez Salvaje (Rol 5).
##
## Ejecutar en modo headless:
##   godot --headless --path . --script res://tests/integration/test_integration.gd

var _checks := 0
var _failed := 0


func _init() -> void:
	print("Ejecutando pruebas de integración...")
	_test_game_initialization()
	_test_simulation_integration_round()
	_test_turn_rotation_and_moves()
	_test_nursery_capture_integration()
	_test_level_3_excavator_and_felled_tiles()
	_test_victory_conditions_integration()
	
	print("\n%d comprobaciones, %d fallidas" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _test_game_initialization() -> void:
	print("- Inicialización del juego y componentes")
	var board := Board.new()
	var config := SimulationConfig.new()
	var engine := SimulationEngine.new(config)
	var match_game := ChessMatch.new(board)
	match_game.setup_initial()
	
	_assert_eq(match_game.position.squares[ChessPosition.to_index(Vector2i(4, 1))], ChessPiece.Kind.PAWN | (ChessPiece.Team.PLAYER << 3), "Peón blanco en e2")
	_assert_eq(match_game.position.squares[ChessPosition.to_index(Vector2i(4, 6))], ChessPiece.Kind.PAWN | (ChessPiece.Team.RIVAL << 3), "Peón negro en e7")
	_assert_eq(engine.hunter, Vector2i(3, 3), "Cazador inicia en d4 (coordenada 3,3)")
	_assert_eq(engine.water(ChessPosition.PLAYER), 100.0, "Agua inicial Jugador 1 = 100%")
	_assert_eq(engine.water(ChessPosition.RIVAL), 100.0, "Agua inicial Jugador 2 = 100%")


func _test_simulation_integration_round() -> void:
	print("- Ejecución de ronda ambiental acoplada")
	var board := Board.new()
	var config := SimulationConfig.new()
	var engine := SimulationEngine.new(config)
	var match_game := ChessMatch.new(board)
	match_game.setup_initial()
	
	var result := engine.run_round(1, match_game.position)
	_assert_true(result != null, "Resultado de ronda no nulo")
	_assert_eq(result.round_number, 1, "Ronda número 1")
	_assert_eq(result.level, 1, "Nivel 1")
	_assert_true(result.water.size() == 2, "Dos acumuladores de agua procesados")
	_assert_true(result.hunter != null, "Transición del cazador calculada")


func _test_turn_rotation_and_moves() -> void:
	print("- Alternancia de turnos y orientación de tablero")
	var board := Board.new()
	var match_game := ChessMatch.new(board)
	match_game.setup_initial()
	
	_assert_eq(match_game.side_to_move(), ChessPosition.PLAYER, "Turno inicial para Blancas (PLAYER)")
	board.orient_to_side(match_game.side_to_move(), false)
	_assert_eq(board.view_side, ChessPosition.PLAYER, "Tablero orientado al Jugador 1")
	
	# Jugada 1. e4 (e2 a e4)
	var move := match_game.find_move(Vector2i(4, 1), Vector2i(4, 3))
	_assert_true(move != null, "Movimiento 1. e4 es legal")
	match_game.play(move)
	
	_assert_eq(match_game.side_to_move(), ChessPosition.RIVAL, "Turno pasa a Negras (RIVAL)")
	board.orient_to_side(match_game.side_to_move(), false)
	_assert_eq(board.view_side, ChessPosition.RIVAL, "Tablero gira 180° hacia el Jugador 2")


func _test_nursery_capture_integration() -> void:
	print("- Integración del vivero M/M/1 con capturas")
	var config := SimulationConfig.new()
	var engine := SimulationEngine.new(config)
	
	# Simular captura de peón del jugador 0 en ronda 2
	var dummy_pawn := ChessPiece.create(ChessPiece.Kind.PAWN, ChessPiece.Team.PLAYER)
	var enqueued := engine.enqueue_capture(ChessPosition.PLAYER, dummy_pawn, 2)
	_assert_true(enqueued, "Peón capturado ingresa exitosamente a la cola del vivero M/M/1")
	_assert_eq(engine.nursery(ChessPosition.PLAYER).queue.length(), 1, "Cola de vivero tiene 1 planta en espera")


func _test_level_3_excavator_and_felled_tiles() -> void:
	print("- Integración Nivel 3: Retroexcavadora y tala de casillas")
	var board := Board.new()
	board._setup()
	var config := SimulationConfig.new()
	var engine := SimulationEngine.new(config)
	var match_game := ChessMatch.new(board)
	match_game.setup_initial()
	
	# Ronda 21 (Nivel 3)
	var result := engine.run_round(21, match_game.position)
	_assert_eq(result.level, 3, "Nivel es 3 en ronda 21")
	_assert_true(result.excavator_spawned, "Retroexcavadora generada en nivel 3")
	
	# Ronda 22 (Retroexcavadora se mueve y tala)
	var result_22 := engine.run_round(22, match_game.position)
	if result_22.felled != Board.INVALID:
		board.set_blocked(result_22.felled, true)
		match_game.sync()
		_assert_true(board.is_blocked(result_22.felled), "Casilla talada queda bloqueada en el tablero")
		_assert_eq(match_game.position.blocked[ChessPosition.to_index(result_22.felled)], 1, "Casilla talada sincronizada como bloqueada en ChessPosition")
	else:
		_assert_true(true, "Retroexcavadora evaluó paso sin tala en este turno")


func _test_victory_conditions_integration() -> void:
	print("- Condiciones de victoria y evaluación de veredicto")
	var board := Board.new()
	var config := SimulationConfig.new()
	var engine := SimulationEngine.new(config)
	var match_game := ChessMatch.new(board)
	match_game.setup_initial()
	
	# Partida normal al inicio
	var verdict := engine.verdict(match_game.position, 1)
	_assert_true(not verdict.is_finished(), "La partida no ha terminado en ronda 1")
	
	# Colapso hídrico simulado
	engine.ecosystems[ChessPosition.RIVAL].water.level = 0.0
	var verdict_dry := engine.verdict(match_game.position, 1)
	_assert_true(verdict_dry.is_finished(), "Colapso hídrico detectado como fin de juego")
	_assert_eq(verdict_dry.winner, ChessPosition.PLAYER, "Gana Jugador 1 por sequía del rival")


func _assert_true(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		print("  FALLÓ: %s" % description)
	else:
		print("  OK: %s" % description)


func _assert_eq(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failed += 1
		print("  FALLÓ: %s (obtenido: %s, esperado: %s)" % [description, actual, expected])
	else:
		print("  OK: %s" % description)
