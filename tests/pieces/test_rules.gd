extends SceneTree
## Pruebas del módulo de piezas y reglas.
##
## Ejecutar desde la raíz del proyecto:
##   godot --headless --path . --script res://tests/pieces/test_rules.gd
## Al final imprime "N comprobaciones, M fallidas".
##
## Incluye "perft": contar todas las posiciones alcanzables a cierta
## profundidad y compararlas con valores publicados. Si coinciden, el
## generador de jugadas (enroques, captura al paso, coronaciones, clavadas)
## es correcto.

const BOARD_SCENE := preload("res://scenes/board/Board.tscn")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("  FALLA: " + message)


func _section(title: String) -> void:
	print("- " + title)


func _run() -> void:
	_test_perft()
	_test_basic_rules()
	_test_special_moves()
	_test_game_end()
	_test_game_specific_rules()
	_test_fen_and_notation()
	_test_board_integration()
	print("\n%d comprobaciones, %d fallidas" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _moves_uci(position: ChessPosition, from: String = "") -> Array:
	var moves: Array[ChessMove]
	if from == "":
		moves = MovementValidator.legal_moves(position)
	else:
		moves = MovementValidator.legal_moves_from(position, Board.algebraic_to_coord(from))
	return moves.map(func(m: ChessMove) -> String: return m.uci())


func _play(position: ChessPosition, uci_moves: Array) -> ChessPosition:
	for text in uci_moves:
		var found: ChessMove = null
		for move in MovementValidator.legal_moves(position):
			if move.uci() == text:
				found = move
		if found == null:
			_check(false, "la jugada %s debería ser legal en %s" % [text, position.to_fen()])
			return position
		position = MovementValidator.apply(position, found)
	return position


func _test_perft() -> void:
	_section("Perft (valores publicados)")
	var cases := [
		["inicial", ChessPosition.START_FEN, [20, 400, 8902]],
		["Kiwipete", "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", [48, 2039]],
		["posición 3", "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1", [14, 191, 2812]],
		["posición 4", "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1", [6, 264]],
		["posición 5", "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8", [44, 1486]],
	]
	for case in cases:
		var position := ChessPosition.from_fen(case[1])
		var expected: Array = case[2]
		for depth in range(1, expected.size() + 1):
			var start := Time.get_ticks_msec()
			var count := MovementValidator.perft(position, depth)
			_check(count == expected[depth - 1], "perft(%d) de %s = %d (esperado %d)" % [depth, case[0], count, expected[depth - 1]])
			if depth == expected.size():
				print("    %s perft(%d) = %d en %d ms" % [case[0], depth, count, Time.get_ticks_msec() - start])


func _test_basic_rules() -> void:
	_section("Movimientos básicos")
	var start := ChessPosition.initial()
	_check(_moves_uci(start, "e2") == ["e2e3", "e2e4"], "peón inicial: 1 o 2 casillas")
	_check(_moves_uci(start, "g1").size() == 2, "caballo g1: f3 y h3")
	_check(_moves_uci(start, "c1").is_empty(), "alfil encerrado al inicio")
	_check(_moves_uci(start, "a1").is_empty(), "torre encerrada al inicio")
	_check(_moves_uci(start, "e7").is_empty(), "no se pueden mover piezas del rival en tu turno")

	var open := ChessPosition.from_fen("4k3/8/8/8/3Q4/8/8/4K3 w - - 0 1")
	_check(_moves_uci(open, "d4").size() == 27, "dama en d4 con tablero libre: 27 casillas")
	var rook := ChessPosition.from_fen("4k3/8/8/8/3R4/8/8/4K3 w - - 0 1")
	_check(_moves_uci(rook, "d4").size() == 14, "torre en d4: 14 casillas")
	var bishop := ChessPosition.from_fen("4k3/8/8/8/3B4/8/8/4K3 w - - 0 1")
	_check(_moves_uci(bishop, "d4").size() == 13, "alfil en d4: 13 casillas")

	var pinned := ChessPosition.from_fen("4k3/4r3/8/8/8/8/4B3/4K3 w - - 0 1")
	_check(_moves_uci(pinned, "e2").is_empty(), "un alfil clavado no se puede mover")
	var check := ChessPosition.from_fen("4k3/4r3/8/8/8/8/3N4/N3K3 w - - 0 1")
	_check(MovementValidator.is_in_check(check, ChessPosition.PLAYER), "torre en e7 da jaque al rey en e1")
	_check(_moves_uci(check, "d2") == ["d2e4"], "en jaque, el caballo de d2 solo puede tapar en e4")
	_check(_moves_uci(check, "a1").is_empty(), "el caballo de a1 no puede tapar: no tiene jugadas")
	_check(not _moves_uci(check, "e1").has("e1e2"), "el rey no puede quedarse en la línea de la torre")


func _test_special_moves() -> void:
	_section("Enroque, captura al paso y coronación")
	var both := ChessPosition.from_fen("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")
	var castles := MovementValidator.legal_moves(both).filter(func(m: ChessMove) -> bool: return m.castle)
	_check(castles.size() == 2, "enroque corto y largo disponibles")
	var attacked := ChessPosition.from_fen("4kr2/8/8/8/8/8/8/R3K2R w KQ - 0 1")
	_check(not _moves_uci(attacked, "e1").has("e1g1"), "no se enroca pasando por una casilla atacada")
	_check(_moves_uci(attacked, "e1").has("e1c1"), "el enroque largo sigue permitido")
	var in_check := ChessPosition.from_fen("4k3/4r3/8/8/8/8/8/R3K2R w KQ - 0 1")
	_check(not _moves_uci(in_check, "e1").has("e1g1") and not _moves_uci(in_check, "e1").has("e1c1"), "no se enroca estando en jaque")
	var moved := _play(ChessPosition.from_fen("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1"), ["e1f1", "e8d8", "f1e1", "d8e8"])
	_check(not _moves_uci(moved, "e1").has("e1g1"), "tras mover el rey se pierde el enroque")
	var castled := _play(both, ["e1g1"])
	_check(castled.piece_at(Vector2i(6, 0)) == ChessPosition.encode(6, 0) and castled.piece_at(Vector2i(5, 0)) == ChessPosition.encode(4, 0),
			"el enroque corto deja rey en g1 y torre en f1")

	var ep := _play(ChessPosition.initial(), ["e2e4", "a7a6", "e4e5", "d7d5"])
	_check(_moves_uci(ep, "e5").has("e5d6"), "captura al paso disponible justo después del avance doble")
	var after_ep := _play(ep, ["e5d6"])
	_check(after_ep.piece_at(Vector2i(3, 4)) == ChessPosition.EMPTY, "la captura al paso retira el peón de d5")
	var late := _play(ep, ["g1f3", "a6a5"])
	_check(not _moves_uci(late, "e5").has("e5d6"), "la captura al paso solo vale en la jugada inmediata")

	var promo := ChessPosition.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1")
	_check(_moves_uci(promo, "b7").size() == 4, "coronación: 4 opciones (dama, torre, alfil, caballo)")
	var queened := _play(promo, ["b7b8q"])
	_check(queened.piece_at(Vector2i(1, 7)) == ChessPosition.encode(5, 0), "corona en dama")


func _test_game_end() -> void:
	_section("Fin de partida")
	var fools := _play(ChessPosition.initial(), ["f2f3", "e7e5", "g2g4", "d8h4"])
	_check(MovementValidator.status(fools) == MovementValidator.Status.CHECKMATE, "mate del loco: jaque mate")
	_check(MovementValidator.winner(fools) == ChessPosition.RIVAL, "gana el rival")
	var stalemate := ChessPosition.from_fen("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
	_check(MovementValidator.status(stalemate) == MovementValidator.Status.STALEMATE, "rey sin jugadas y sin jaque: ahogado")
	_check(MovementValidator.winner(stalemate) == -1, "el ahogado no tiene ganador")
	var no_king := ChessPosition.from_fen("8/8/8/8/8/8/8/4K3 b - - 0 1")
	_check(MovementValidator.status(no_king) == MovementValidator.Status.KING_LOST, "sin rey rival: rey perdido")
	_check(MovementValidator.winner(no_king) == ChessPosition.PLAYER, "gana quien conserva su rey")
	_check(MovementValidator.status(ChessPosition.initial()) == MovementValidator.Status.PLAYING, "al inicio la partida sigue")


func _test_game_specific_rules() -> void:
	_section("Reglas del juego: cazador y casillas bloqueadas")
	var hunter := ChessPosition.from_fen("4k3/8/8/8/3x4/8/8/3RK3 w - - 0 1")
	var rook_moves := _moves_uci(hunter, "d1")
	_check(rook_moves.has("d1d3") and not rook_moves.has("d1d4") and not rook_moves.has("d1d5"), "el cazador bloquea a la torre y no se captura")
	hunter.hunter_capturable = true
	_check(_moves_uci(hunter, "d1").has("d1d4"), "con hunter_capturable se puede capturar al cazador")
	var near := ChessPosition.from_fen("4k3/8/8/8/8/8/3x4/4K3 w - - 0 1")
	_check(not MovementValidator.is_in_check(near, ChessPosition.PLAYER), "el cazador no da jaque")
	_check(not _moves_uci(near, "e1").has("e1d2"), "el rey no puede pisar al cazador")

	var blocked := ChessPosition.from_fen("4k3/8/8/8/8/8/8/1N1RK3 w - - 0 1")
	blocked.blocked[ChessPosition.to_index(Vector2i(3, 2))] = 1 # d3
	blocked.blocked[ChessPosition.to_index(Vector2i(2, 2))] = 1 # c3
	var rook := _moves_uci(blocked, "d1")
	_check(rook.has("d1d2") and not rook.has("d1d3") and not rook.has("d1d4"), "la torre no pisa ni atraviesa una casilla bloqueada")
	var knight := _moves_uci(blocked, "b1")
	_check(not knight.has("b1c3") and knight.has("b1a3") and knight.has("b1d2"), "el caballo no cae en casilla bloqueada")
	blocked.blocked[ChessPosition.to_index(Vector2i(1, 1))] = 1 # b2
	_check(_moves_uci(blocked, "b1").has("b1a3"), "el caballo sí salta por encima de una bloqueada")
	blocked.blocked_passable = true
	_check(_moves_uci(blocked, "d1").has("d1d3") and _moves_uci(blocked, "d1").has("d1d4"), "con blocked_passable la torre pisa y atraviesa")

	var pawn := ChessPosition.initial()
	pawn.blocked[ChessPosition.to_index(Vector2i(4, 2))] = 1 # e3
	_check(_moves_uci(pawn, "e2").is_empty(), "un peón no avanza a una casilla bloqueada (ni salta dos)")


func _test_fen_and_notation() -> void:
	_section("FEN y notación")
	for fen in [ChessPosition.START_FEN, "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", "4k3/8/8/3x4/8/8/8/4K3 b - - 3 20"]:
		_check(ChessPosition.from_fen(fen).to_fen() == fen, "ida y vuelta FEN: " + fen)
	var after := _play(ChessPosition.initial(), ["e2e4"])
	_check(after.to_fen() == "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1", "FEN tras 1. e4")
	var names := {}
	for move in MovementValidator.legal_moves(ChessPosition.initial()):
		names[move.uci()] = move.notation()
	_check(names["e2e4"] == "e4" and names["g1f3"] == "Cf3", "notación: e4 y Cf3")
	var castle := ChessPosition.from_fen("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")
	var notations := MovementValidator.legal_moves(castle).filter(func(m): return m.castle).map(func(m): return m.notation())
	_check(notations.has("O-O") and notations.has("O-O-O"), "notación de enroques")
	var promo := MovementValidator.legal_moves(ChessPosition.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1"))
	_check(promo.map(func(m): return m.notation()).has("b8=D"), "notación de coronación en dama: b8=D")


func _test_board_integration() -> void:
	_section("Integración con el tablero 3D (ChessMatch)")
	var board: Board = BOARD_SCENE.instantiate()
	board.animations_enabled = false
	board.play_intro_on_ready = false
	root.add_child(board)
	var game := ChessMatch.new(board)
	game.setup_initial()
	_check(board.get_all_pieces().size() == 32, "posición inicial: 32 piezas en el tablero")
	var king := board.get_piece_at(Vector2i(4, 0)) as ChessPiece
	var queen := board.get_piece_at(Vector2i(3, 7)) as ChessPiece
	_check(king != null and king.kind == ChessPiece.Kind.KING and king.side == ChessPiece.Team.PLAYER, "rey del jugador en e1")
	_check(queen != null and queen.kind == ChessPiece.Kind.QUEEN and queen.side == ChessPiece.Team.RIVAL, "dama rival en d8")
	_check(game.position.to_fen() == ChessPosition.START_FEN, "la posición coincide con el tablero")

	var e4 := game.find_move(Vector2i(4, 1), Vector2i(4, 3))
	_check(e4 != null, "e2-e4 es legal")
	game.play(e4)
	_check(board.is_occupied(Vector2i(4, 3)) and board.is_empty(Vector2i(4, 1)), "el peón se movió en el tablero")
	_check(game.side_to_move() == ChessPosition.RIVAL, "turno del rival")
	_check(game.find_move(Vector2i(4, 3), Vector2i(4, 4)) == null, "no se puede mover dos veces seguidas")

	game.setup_initial("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	game.play(game.find_move(Vector2i(4, 0), Vector2i(6, 0)))
	_check((board.get_piece_at(Vector2i(6, 0)) as ChessPiece).kind == ChessPiece.Kind.KING, "enroque en el tablero: rey en g1")
	_check((board.get_piece_at(Vector2i(5, 0)) as ChessPiece).kind == ChessPiece.Kind.ROOK and board.is_empty(Vector2i(7, 0)), "y torre en f1")

	game.setup_initial("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	var captured := game.play(game.find_move(Vector2i(4, 4), Vector2i(3, 5)))
	_check(captured != null and captured.kind == ChessPiece.Kind.PAWN, "captura al paso: devuelve el peón capturado")
	_check(board.is_empty(Vector2i(3, 4)), "y lo retira de d5")
	if captured:
		captured.free()

	game.setup_initial("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1")
	game.play(game.find_move(Vector2i(1, 6), Vector2i(1, 7)))
	_check((board.get_piece_at(Vector2i(1, 7)) as ChessPiece).kind == ChessPiece.Kind.QUEEN, "coronación: el modelo pasa a danta (dama)")

	game.setup_initial("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	board.destroy_piece(Vector2i(7, 0), false) # el cazador destruye la torre de h1
	game.sync()
	_check(not (game.position.castling & ChessPosition.CASTLE_PLAYER_KINGSIDE), "sin la torre de h1 se pierde el enroque corto")
	_check(game.position.castling & ChessPosition.CASTLE_PLAYER_QUEENSIDE, "el enroque largo se conserva")
	var hunter := ChessPiece.create(ChessPiece.Kind.HUNTER, ChessPiece.Team.NEUTRAL)
	board.place_piece(hunter, Vector2i(3, 0))
	board.set_blocked(Vector2i(4, 1))
	game.sync()
	_check(game.position.piece_at(Vector2i(3, 0)) == ChessPosition.NEUTRAL, "el cazador se lee como ocupante neutral")
	_check(game.position.blocked[ChessPosition.to_index(Vector2i(4, 1))] == 1, "las casillas bloqueadas pasan a las reglas")
	_check(game.find_move(Vector2i(4, 0), Vector2i(2, 0)) == null, "con el cazador en d1 no se puede enrocar largo")
	board.queue_free()
