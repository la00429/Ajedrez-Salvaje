class_name ChessPosition
extends RefCounted
## Estado de una partida para las reglas de ajedrez, independiente de lo
## visual: qué hay en cada casilla, a quién le toca, enroques disponibles y
## casilla de captura al paso. [MovementValidator] trabaja sobre esta clase.
##
## Casillas: índice 0-63 = fila * 8 + columna (a1 = 0, h1 = 7, a8 = 56).
## Cada casilla guarda un código: 0 vacía, tipo | (bando << 3) para una pieza
## (tipos de [enum ChessPiece.Kind], bandos 0 jugador / 1 rival) o
## [constant NEUTRAL] para el cazador u otro ocupante neutral.
##
## Reglas configurables (decisiones del equipo):
## [member hunter_capturable] y [member blocked_passable].

const EMPTY := 0
## Ocupante neutral (cazador): bloquea el paso y no ataca.
const NEUTRAL := 16
const SIDE_SHIFT := 3

const PLAYER := 0
const RIVAL := 1

const CASTLE_PLAYER_KINGSIDE := 1
const CASTLE_PLAYER_QUEENSIDE := 2
const CASTLE_RIVAL_KINGSIDE := 4
const CASTLE_RIVAL_QUEENSIDE := 8

## Posición inicial FIDE. Mayúsculas = jugador, minúsculas = rival.
const START_FEN := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
const FEN_LETTERS := "pnbrqk"

var squares := PackedInt32Array()
## 1 si la casilla está bloqueada (catástrofe, tala...).
var blocked := PackedByteArray()
var side_to_move := PLAYER
var castling := 0
## Índice de la casilla de captura al paso, o -1.
var en_passant := -1
var halfmove_clock := 0
var fullmove_number := 1
## Si es true, las piezas pueden capturar al cazador.
var hunter_capturable := false
## Si es true, las casillas bloqueadas se pueden pisar y atravesar.
var blocked_passable := false


func _init() -> void:
	squares.resize(64)
	blocked.resize(64)


static func encode(kind: int, side: int) -> int:
	return kind | (side << SIDE_SHIFT)


## Tipo de pieza de un código (1-6), [constant NEUTRAL] o 0.
static func kind_of(code: int) -> int:
	return code if code == NEUTRAL else code & 7


## Bando de un código: 0, 1, o -1 si está vacía o es neutral.
static func side_of(code: int) -> int:
	if code == EMPTY or code == NEUTRAL:
		return -1
	return code >> SIDE_SHIFT


static func to_index(coord: Vector2i) -> int:
	return coord.y * 8 + coord.x


static func to_coord(index: int) -> Vector2i:
	return Vector2i(index % 8, index / 8)


func piece_at(coord: Vector2i) -> int:
	return squares[to_index(coord)]


func set_piece(coord: Vector2i, code: int) -> void:
	squares[to_index(coord)] = code


## Índice del rey de un bando, o -1 si no está (por ejemplo, si lo destruyó
## el cazador).
func find_king(side: int) -> int:
	var king := encode(6, side)
	for i in 64:
		if squares[i] == king:
			return i
	return -1


func duplicate_position() -> ChessPosition:
	var copy := ChessPosition.new()
	copy.squares = squares.duplicate()
	copy.blocked = blocked.duplicate()
	copy.side_to_move = side_to_move
	copy.castling = castling
	copy.en_passant = en_passant
	copy.halfmove_clock = halfmove_clock
	copy.fullmove_number = fullmove_number
	copy.hunter_capturable = hunter_capturable
	copy.blocked_passable = blocked_passable
	return copy


static func initial() -> ChessPosition:
	return from_fen(START_FEN)


## Lee una posición en notación FEN. Extensión: "x" marca un ocupante neutral.
static func from_fen(fen: String) -> ChessPosition:
	var position := ChessPosition.new()
	var parts := fen.strip_edges().split(" ", false)
	var rows := parts[0].split("/")
	for r in 8:
		var y := 7 - r
		var x := 0
		for ch in rows[r]:
			if ch.is_valid_int():
				x += ch.to_int()
			elif ch == "x":
				position.squares[y * 8 + x] = NEUTRAL
				x += 1
			else:
				var kind := FEN_LETTERS.find(ch.to_lower()) + 1
				var side := PLAYER if ch == ch.to_upper() else RIVAL
				position.squares[y * 8 + x] = encode(kind, side)
				x += 1
	position.side_to_move = PLAYER if parts.size() < 2 or parts[1] == "w" else RIVAL
	if parts.size() > 2:
		for ch in parts[2]:
			match ch:
				"K": position.castling |= CASTLE_PLAYER_KINGSIDE
				"Q": position.castling |= CASTLE_PLAYER_QUEENSIDE
				"k": position.castling |= CASTLE_RIVAL_KINGSIDE
				"q": position.castling |= CASTLE_RIVAL_QUEENSIDE
	if parts.size() > 3 and parts[3] != "-":
		position.en_passant = to_index(Board.algebraic_to_coord(parts[3]))
	if parts.size() > 4:
		position.halfmove_clock = parts[4].to_int()
	if parts.size() > 5:
		position.fullmove_number = maxi(1, parts[5].to_int())
	return position


func to_fen() -> String:
	var rows: PackedStringArray = []
	for r in 8:
		var y := 7 - r
		var row := ""
		var empty := 0
		for x in 8:
			var code := squares[y * 8 + x]
			if code == EMPTY:
				empty += 1
				continue
			if empty > 0:
				row += str(empty)
				empty = 0
			if code == NEUTRAL:
				row += "x"
			else:
				var letter := FEN_LETTERS[kind_of(code) - 1]
				row += letter.to_upper() if side_of(code) == PLAYER else letter
		if empty > 0:
			row += str(empty)
		rows.append(row)
	var rights := ""
	if castling & CASTLE_PLAYER_KINGSIDE:
		rights += "K"
	if castling & CASTLE_PLAYER_QUEENSIDE:
		rights += "Q"
	if castling & CASTLE_RIVAL_KINGSIDE:
		rights += "k"
	if castling & CASTLE_RIVAL_QUEENSIDE:
		rights += "q"
	var ep := Board.coord_to_algebraic(to_coord(en_passant)) if en_passant >= 0 else "-"
	return "%s %s %s %s %d %d" % ["/".join(rows), "w" if side_to_move == PLAYER else "b",
			rights if rights != "" else "-", ep, halfmove_clock, fullmove_number]


## Arma la posición a partir de lo que hay en el tablero 3D. Conserva el turno,
## los enroques y la captura al paso de [param previous] (si se da), pero los
## invalida si el tablero ya no los permite (por ejemplo, si el cazador
## destruyó una torre). Cualquier ocupante que no sea [ChessPiece] o sea el
## cazador cuenta como neutral.
static func from_board(board: Board, previous: ChessPosition = null) -> ChessPosition:
	var position := previous.duplicate_position() if previous else ChessPosition.new()
	if previous == null:
		position.castling = CASTLE_PLAYER_KINGSIDE | CASTLE_PLAYER_QUEENSIDE | CASTLE_RIVAL_KINGSIDE | CASTLE_RIVAL_QUEENSIDE
	for i in 64:
		var coord := to_coord(i)
		position.blocked[i] = 1 if board.is_blocked(coord) else 0
		var occupant := board.get_piece_at(coord)
		if occupant == null:
			position.squares[i] = EMPTY
		elif occupant is ChessPiece and occupant.kind != ChessPiece.Kind.HUNTER:
			position.squares[i] = encode(occupant.kind, occupant.side)
		else:
			position.squares[i] = NEUTRAL
	position.validate_rights()
	return position


## Quita los enroques y la captura al paso que el tablero ya no permite.
func validate_rights() -> void:
	var checks := [
		[CASTLE_PLAYER_KINGSIDE, 4, 7, PLAYER], [CASTLE_PLAYER_QUEENSIDE, 4, 0, PLAYER],
		[CASTLE_RIVAL_KINGSIDE, 60, 63, RIVAL], [CASTLE_RIVAL_QUEENSIDE, 60, 56, RIVAL],
	]
	for check in checks:
		if castling & check[0]:
			if squares[check[1]] != encode(6, check[3]) or squares[check[2]] != encode(4, check[3]):
				castling &= ~check[0]
	if en_passant >= 0:
		# El peón que avanzó dos casillas debe seguir justo delante de la
		# casilla de paso (e3 -> peón en e4; e6 -> peón en e5).
		var mover := RIVAL if side_to_move == PLAYER else PLAYER
		var pawn_index := en_passant + (8 if mover == PLAYER else -8)
		if squares[en_passant] != EMPTY or pawn_index < 0 or pawn_index > 63 or squares[pawn_index] != encode(1, mover):
			en_passant = -1
