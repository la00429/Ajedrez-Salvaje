class_name ChessMatch
extends RefCounted
## Une las reglas de ajedrez ([ChessPosition] + [MovementValidator]) con el
## tablero 3D ([Board]).
##
## Uso típico (módulo de integración):
## [codeblock]
## var match := ChessMatch.new(board)
## match.setup_initial()                      # 32 piezas en posición FIDE
## var moves := match.legal_moves_from(coord) # para resaltar destinos
## var captured := match.play(moves[0])       # ejecuta en el tablero
## if captured: vivero.enqueue(captured)      # o captured.queue_free()
## match.sync()                               # tras cambios del cazador, etc.
## [/codeblock]

## Se emite después de jugar una jugada en el tablero.
signal move_played(move: ChessMove)

var board: Board
var position: ChessPosition
var history: Array[ChessMove] = []


func _init(p_board: Board, p_position: ChessPosition = null) -> void:
	board = p_board
	position = p_position if p_position else ChessPosition.from_board(board)


## Limpia el tablero y coloca las piezas de [param fen] (por defecto, la
## posición inicial FIDE). [param piece_scale] escala los modelos.
func setup_initial(fen: String = ChessPosition.START_FEN, piece_scale: float = 1.0) -> void:
	board.clear_pieces()
	history.clear()
	position = ChessPosition.from_fen(fen)
	for index in 64:
		var code := position.squares[index]
		if code == ChessPosition.EMPTY:
			continue
		var piece: ChessPiece
		if code == ChessPosition.NEUTRAL:
			piece = ChessPiece.create(ChessPiece.Kind.HUNTER, ChessPiece.Team.NEUTRAL)
		else:
			piece = ChessPiece.create(ChessPosition.kind_of(code) as ChessPiece.Kind, ChessPosition.side_of(code) as ChessPiece.Team)
		piece.scale = Vector3.ONE * piece_scale
		board.place_piece(piece, ChessPosition.to_coord(index))
	position.validate_rights()


## Vuelve a leer el tablero (después de que el cazador, el vivero o una
## catástrofe lo cambien). Conserva el turno y los derechos que sigan siendo válidos.
func sync() -> void:
	position = ChessPosition.from_board(board, position)


func side_to_move() -> int:
	return position.side_to_move


func legal_moves() -> Array[ChessMove]:
	return MovementValidator.legal_moves(position)


func legal_moves_from(coord: Vector2i) -> Array[ChessMove]:
	return MovementValidator.legal_moves_from(position, coord)


## Busca la jugada legal de [param from] a [param to]. Si es una coronación,
## elige [param promotion] (dama por defecto). Devuelve null si no es legal.
func find_move(from: Vector2i, to: Vector2i, promotion: int = MovementValidator.QUEEN) -> ChessMove:
	var to_index := ChessPosition.to_index(to)
	for move in legal_moves_from(from):
		if move.to == to_index and (move.promotion == 0 or move.promotion == promotion):
			return move
	return null


func status() -> MovementValidator.Status:
	return MovementValidator.status(position)


func winner() -> int:
	return MovementValidator.winner(position)


func is_in_check(side: int) -> bool:
	return MovementValidator.is_in_check(position, side)


## Ejecuta una jugada legal en el tablero y actualiza la posición. Devuelve la
## pieza capturada [b]sin liberarla[/b] (para el vivero), o null.
func play(move: ChessMove) -> ChessPiece:
	var captured: ChessPiece = null
	var captured_coord := move.captured_coord()
	if board.is_occupied(captured_coord) and captured_coord != move.from_coord():
		captured = board.remove_piece(captured_coord) as ChessPiece
	board.move_piece(move.from_coord(), move.to_coord())
	if move.castle:
		board.move_piece(move.rook_from(), move.rook_to())
	if move.promotion != 0:
		var piece := board.get_piece_at(move.to_coord()) as ChessPiece
		if piece:
			piece.kind = move.promotion as ChessPiece.Kind
	position = MovementValidator.apply(position, move)
	history.append(move)
	move_played.emit(move)
	return captured
