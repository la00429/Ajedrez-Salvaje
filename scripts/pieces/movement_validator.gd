class_name MovementValidator
extends RefCounted
## Reglas de ajedrez FIDE para Ajedrez Salvaje, sobre una [ChessPosition].
##
## Genera las jugadas legales de las 6 piezas (peón, caballo, alfil, torre,
## dama y rey), con enroque, captura al paso y coronación, y detecta jaque,
## jaque mate y ahogado. Una jugada es legal solo si no deja al propio rey
## en jaque: nunca se asume que es válida porque la interfaz deja elegirla.
##
## Reglas propias del juego:
## - El cazador (ocupante neutral) bloquea el paso y no ataca. Solo se puede
##   capturar si [member ChessPosition.hunter_capturable] es true.
## - Las casillas bloqueadas no se pueden pisar ni atravesar (el caballo sí
##   puede saltar por encima), salvo que [member ChessPosition.blocked_passable]
##   sea true.
## - Si el cazador destruye un rey, la partida termina ([constant KING_LOST]).
##
## No se implementan las tablas por 50 jugadas ni por triple repetición.

enum Status {
	PLAYING, ## La partida sigue, sin jaque.
	CHECK, ## El bando al que le toca está en jaque.
	CHECKMATE, ## Jaque mate: pierde el bando al que le toca.
	STALEMATE, ## Ahogado: tablas.
	KING_LOST, ## Un bando perdió su rey (por ejemplo, por el cazador).
}

const PAWN := 1
const KNIGHT := 2
const BISHOP := 3
const ROOK := 4
const QUEEN := 5
const KING := 6
const EMPTY := ChessPosition.EMPTY
const NEUTRAL := ChessPosition.NEUTRAL

const KNIGHT_JUMPS: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
	Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2),
]
const ROOK_DIRECTIONS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const BISHOP_DIRECTIONS: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const KING_STEPS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]
const PROMOTIONS: Array[int] = [QUEEN, ROOK, BISHOP, KNIGHT]


# ---------------------------------------------------------------------------
# Consultas principales
# ---------------------------------------------------------------------------

## Todas las jugadas legales del bando al que le toca.
static func legal_moves(position: ChessPosition) -> Array[ChessMove]:
	var result: Array[ChessMove] = []
	var side := position.side_to_move
	for move in pseudo_moves(position):
		var after := apply(position, move)
		var king := after.find_king(side)
		if king == -1 or not is_square_attacked(after, king, 1 - side):
			result.append(move)
	return result


## Jugadas legales de la pieza en [param coord] (vacío si no es del bando al
## que le toca).
static func legal_moves_from(position: ChessPosition, coord: Vector2i) -> Array[ChessMove]:
	var from := ChessPosition.to_index(coord)
	var result: Array[ChessMove] = []
	for move in legal_moves(position):
		if move.from == from:
			result.append(move)
	return result


## true si el rey de [param side] está atacado. Sin rey, devuelve false.
static func is_in_check(position: ChessPosition, side: int) -> bool:
	var king := position.find_king(side)
	return king != -1 and is_square_attacked(position, king, 1 - side)


## Estado de la partida para el bando al que le toca.
static func status(position: ChessPosition) -> Status:
	if position.find_king(ChessPosition.PLAYER) == -1 or position.find_king(ChessPosition.RIVAL) == -1:
		return Status.KING_LOST
	var in_check := is_in_check(position, position.side_to_move)
	if legal_moves(position).is_empty():
		return Status.CHECKMATE if in_check else Status.STALEMATE
	return Status.CHECK if in_check else Status.PLAYING


## Bando ganador: tras un jaque mate gana el que no tiene el turno; si falta
## un rey, gana el otro. Devuelve -1 si no hay ganador (partida en curso o tablas).
static func winner(position: ChessPosition) -> int:
	var player_king := position.find_king(ChessPosition.PLAYER) != -1
	var rival_king := position.find_king(ChessPosition.RIVAL) != -1
	if player_king != rival_king:
		return ChessPosition.PLAYER if player_king else ChessPosition.RIVAL
	if not player_king:
		return -1
	if status(position) == Status.CHECKMATE:
		return 1 - position.side_to_move
	return -1


## Nueva posición después de jugar [param move] (no modifica la original).
static func apply(position: ChessPosition, move: ChessMove) -> ChessPosition:
	var next := position.duplicate_position()
	var side := ChessPosition.side_of(move.piece)
	next.squares[move.from] = EMPTY
	if move.en_passant:
		next.squares[ChessPosition.to_index(move.captured_coord())] = EMPTY
	if move.castle:
		var rook_from := ChessPosition.to_index(move.rook_from())
		next.squares[ChessPosition.to_index(move.rook_to())] = next.squares[rook_from]
		next.squares[rook_from] = EMPTY
	next.squares[move.to] = ChessPosition.encode(move.promotion, side) if move.promotion != 0 else move.piece

	# Derechos de enroque: se pierden si se mueve el rey o una torre, o si
	# capturan una torre en su casilla inicial.
	if ChessPosition.kind_of(move.piece) == KING:
		next.castling &= ~(ChessPosition.CASTLE_PLAYER_KINGSIDE | ChessPosition.CASTLE_PLAYER_QUEENSIDE) if side == ChessPosition.PLAYER \
				else ~(ChessPosition.CASTLE_RIVAL_KINGSIDE | ChessPosition.CASTLE_RIVAL_QUEENSIDE)
	for corner in [[0, ChessPosition.CASTLE_PLAYER_QUEENSIDE], [7, ChessPosition.CASTLE_PLAYER_KINGSIDE],
			[56, ChessPosition.CASTLE_RIVAL_QUEENSIDE], [63, ChessPosition.CASTLE_RIVAL_KINGSIDE]]:
		if move.from == corner[0] or move.to == corner[0]:
			next.castling &= ~corner[1]

	next.en_passant = (move.from + move.to) / 2 if move.double_push else -1
	next.halfmove_clock = 0 if ChessPosition.kind_of(move.piece) == PAWN or move.is_capture() else position.halfmove_clock + 1
	if side == ChessPosition.RIVAL:
		next.fullmove_number += 1
	next.side_to_move = 1 - side
	return next


## Cuenta las posiciones alcanzables en [param depth] jugadas (prueba "perft").
## Sirve para verificar el generador contra valores conocidos.
static func perft(position: ChessPosition, depth: int) -> int:
	if depth == 0:
		return 1
	var moves := legal_moves(position)
	if depth == 1:
		return moves.size()
	var total := 0
	for move in moves:
		total += perft(apply(position, move), depth - 1)
	return total


# ---------------------------------------------------------------------------
# Generación de jugadas
# ---------------------------------------------------------------------------

## Jugadas que respetan el movimiento de cada pieza, sin comprobar si dejan
## al propio rey en jaque.
static func pseudo_moves(position: ChessPosition) -> Array[ChessMove]:
	var moves: Array[ChessMove] = []
	var side := position.side_to_move
	for index in 64:
		var code := position.squares[index]
		if ChessPosition.side_of(code) != side:
			continue
		var coord := ChessPosition.to_coord(index)
		match ChessPosition.kind_of(code):
			PAWN:
				_pawn_moves(position, index, coord, code, moves)
			KNIGHT:
				for jump in KNIGHT_JUMPS:
					_add_step(position, index, coord + jump, code, moves)
			BISHOP:
				_slide(position, index, coord, code, BISHOP_DIRECTIONS, moves)
			ROOK:
				_slide(position, index, coord, code, ROOK_DIRECTIONS, moves)
			QUEEN:
				_slide(position, index, coord, code, BISHOP_DIRECTIONS, moves)
				_slide(position, index, coord, code, ROOK_DIRECTIONS, moves)
			KING:
				for step in KING_STEPS:
					_add_step(position, index, coord + step, code, moves)
				_castling_moves(position, index, code, moves)
	return moves


static func _enterable(position: ChessPosition, index: int) -> bool:
	return position.blocked_passable or position.blocked[index] == 0


## true si una pieza de [param side] puede capturar lo que hay en la casilla.
static func _capturable(position: ChessPosition, code: int, side: int) -> bool:
	if code == NEUTRAL:
		return position.hunter_capturable
	return code != EMPTY and ChessPosition.side_of(code) != side


static func _add_step(position: ChessPosition, from: int, to_coord: Vector2i, code: int, moves: Array[ChessMove]) -> void:
	if not Board.is_inside(to_coord):
		return
	var to := ChessPosition.to_index(to_coord)
	if not _enterable(position, to):
		return
	var target := position.squares[to]
	if target == EMPTY or _capturable(position, target, ChessPosition.side_of(code)):
		var move := ChessMove.new(from, to, code)
		move.captured = target
		moves.append(move)


static func _slide(position: ChessPosition, from: int, coord: Vector2i, code: int, directions: Array[Vector2i], moves: Array[ChessMove]) -> void:
	var side := ChessPosition.side_of(code)
	for direction in directions:
		var current := coord + direction
		while Board.is_inside(current):
			var to := ChessPosition.to_index(current)
			if not _enterable(position, to):
				break
			var target := position.squares[to]
			if target == EMPTY:
				moves.append(ChessMove.new(from, to, code))
			else:
				if _capturable(position, target, side):
					var move := ChessMove.new(from, to, code)
					move.captured = target
					moves.append(move)
				break
			current += direction


static func _pawn_moves(position: ChessPosition, from: int, coord: Vector2i, code: int, moves: Array[ChessMove]) -> void:
	var side := ChessPosition.side_of(code)
	var forward := 1 if side == ChessPosition.PLAYER else -1
	var start_row := 1 if side == ChessPosition.PLAYER else 6
	var last_row := 7 if side == ChessPosition.PLAYER else 0
	var one := coord + Vector2i(0, forward)
	if Board.is_inside(one):
		var one_index := ChessPosition.to_index(one)
		if position.squares[one_index] == EMPTY and _enterable(position, one_index):
			_add_pawn_move(from, one_index, code, 0, one.y == last_row, moves)
			var two := coord + Vector2i(0, forward * 2)
			var two_index := ChessPosition.to_index(two)
			if coord.y == start_row and position.squares[two_index] == EMPTY and _enterable(position, two_index):
				var double := ChessMove.new(from, two_index, code)
				double.double_push = true
				moves.append(double)
	for dx in [-1, 1]:
		var target_coord: Vector2i = coord + Vector2i(dx, forward)
		if not Board.is_inside(target_coord):
			continue
		var to := ChessPosition.to_index(target_coord)
		if not _enterable(position, to):
			continue
		var target := position.squares[to]
		if _capturable(position, target, side):
			_add_pawn_move(from, to, code, target, target_coord.y == last_row, moves)
		elif to == position.en_passant and target == EMPTY:
			var move := ChessMove.new(from, to, code)
			move.en_passant = true
			move.captured = ChessPosition.encode(PAWN, 1 - side)
			moves.append(move)


static func _add_pawn_move(from: int, to: int, code: int, captured: int, promotes: bool, moves: Array[ChessMove]) -> void:
	if not promotes:
		var move := ChessMove.new(from, to, code)
		move.captured = captured
		moves.append(move)
		return
	for kind in PROMOTIONS:
		var promotion := ChessMove.new(from, to, code)
		promotion.captured = captured
		promotion.promotion = kind
		moves.append(promotion)


static func _castling_moves(position: ChessPosition, from: int, code: int, moves: Array[ChessMove]) -> void:
	var side := ChessPosition.side_of(code)
	var home := 4 if side == ChessPosition.PLAYER else 60
	if from != home:
		return
	var enemy := 1 - side
	var kingside := ChessPosition.CASTLE_PLAYER_KINGSIDE if side == ChessPosition.PLAYER else ChessPosition.CASTLE_RIVAL_KINGSIDE
	var queenside := ChessPosition.CASTLE_PLAYER_QUEENSIDE if side == ChessPosition.PLAYER else ChessPosition.CASTLE_RIVAL_QUEENSIDE
	var rook := ChessPosition.encode(ROOK, side)
	if not (position.castling & (kingside | queenside)) or is_square_attacked(position, home, enemy):
		return
	if position.castling & kingside and position.squares[home + 3] == rook \
			and _free(position, [home + 1, home + 2]) \
			and not is_square_attacked(position, home + 1, enemy) and not is_square_attacked(position, home + 2, enemy):
		var move := ChessMove.new(from, home + 2, code)
		move.castle = true
		moves.append(move)
	if position.castling & queenside and position.squares[home - 4] == rook \
			and _free(position, [home - 1, home - 2, home - 3]) \
			and not is_square_attacked(position, home - 1, enemy) and not is_square_attacked(position, home - 2, enemy):
		var move := ChessMove.new(from, home - 2, code)
		move.castle = true
		moves.append(move)


static func _free(position: ChessPosition, indices: Array) -> bool:
	for index in indices:
		if position.squares[index] != EMPTY or not _enterable(position, index):
			return false
	return true


# ---------------------------------------------------------------------------
# Ataques
# ---------------------------------------------------------------------------

## true si alguna pieza de [param by_side] ataca la casilla [param index].
static func is_square_attacked(position: ChessPosition, index: int, by_side: int) -> bool:
	# Nadie puede entrar a una casilla bloqueada, así que nadie la ataca.
	if not _enterable(position, index):
		return false
	var coord := ChessPosition.to_coord(index)
	var forward := 1 if by_side == ChessPosition.PLAYER else -1
	var pawn := ChessPosition.encode(PAWN, by_side)
	for dx in [-1, 1]:
		var source: Vector2i = coord + Vector2i(dx, -forward)
		if Board.is_inside(source) and position.squares[ChessPosition.to_index(source)] == pawn:
			return true
	var knight := ChessPosition.encode(KNIGHT, by_side)
	for jump in KNIGHT_JUMPS:
		var source := coord + jump
		if Board.is_inside(source) and position.squares[ChessPosition.to_index(source)] == knight:
			return true
	var king := ChessPosition.encode(KING, by_side)
	for step in KING_STEPS:
		var source := coord + step
		if Board.is_inside(source) and position.squares[ChessPosition.to_index(source)] == king:
			return true
	var queen := ChessPosition.encode(QUEEN, by_side)
	if _ray_hits(position, coord, ROOK_DIRECTIONS, ChessPosition.encode(ROOK, by_side), queen):
		return true
	return _ray_hits(position, coord, BISHOP_DIRECTIONS, ChessPosition.encode(BISHOP, by_side), queen)


static func _ray_hits(position: ChessPosition, coord: Vector2i, directions: Array[Vector2i], piece_a: int, piece_b: int) -> bool:
	for direction in directions:
		var current := coord + direction
		while Board.is_inside(current):
			var index := ChessPosition.to_index(current)
			var code := position.squares[index]
			if code != EMPTY:
				if code == piece_a or code == piece_b:
					return true
				break
			if not _enterable(position, index):
				break
			current += direction
	return false
