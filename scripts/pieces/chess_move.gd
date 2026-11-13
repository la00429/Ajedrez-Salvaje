class_name ChessMove
extends RefCounted
## Una jugada de ajedrez: de qué casilla a qué casilla, y si es captura,
## coronación, enroque o captura al paso.
##
## Las casillas se guardan como índices 0-63 (fila * 8 + columna), igual que
## en [ChessPosition]. Para trabajar con el tablero usar [method from_coord]
## y [method to_coord].

var from := 0
var to := 0
## Código de la pieza que mueve (ver [ChessPosition]).
var piece := 0
## Código de la pieza capturada (0 si no captura).
var captured := 0
## Tipo al que corona un peón (0 si no corona).
var promotion := 0
var castle := false
var en_passant := false
var double_push := false


func _init(p_from: int = 0, p_to: int = 0, p_piece: int = 0) -> void:
	from = p_from
	to = p_to
	piece = p_piece


func from_coord() -> Vector2i:
	return Vector2i(from % 8, from / 8)


func to_coord() -> Vector2i:
	return Vector2i(to % 8, to / 8)


## Casilla de la pieza capturada (en la captura al paso no es la de destino).
func captured_coord() -> Vector2i:
	if en_passant:
		return Vector2i(to % 8, from / 8)
	return to_coord()


func is_capture() -> bool:
	return captured != 0


## En un enroque, casilla de origen de la torre.
func rook_from() -> Vector2i:
	var row := from / 8
	return Vector2i(7 if to % 8 == 6 else 0, row)


## En un enroque, casilla de destino de la torre.
func rook_to() -> Vector2i:
	var row := from / 8
	return Vector2i(5 if to % 8 == 6 else 3, row)


## Notación algebraica en español: "e4", "Cf3", "Axc4", "O-O", "e8=D".
func notation() -> String:
	if castle:
		return "O-O" if to % 8 == 6 else "O-O-O"
	const LETTERS := ["", "", "C", "A", "T", "D", "R"]
	var kind := piece & 7
	var target := Board.coord_to_algebraic(to_coord())
	var text := ""
	if kind == 1:
		if is_capture():
			text = Board.FILES[from % 8] + "x"
		text += target
		if promotion != 0:
			text += "=" + LETTERS[promotion]
	else:
		text = LETTERS[kind] + ("x" if is_capture() else "") + target
	return text


## Texto UCI ("e2e4", "e7e8q"), útil para pruebas y registros.
func uci() -> String:
	const PROMO := ["", "", "n", "b", "r", "q", ""]
	return Board.coord_to_algebraic(from_coord()) + Board.coord_to_algebraic(to_coord()) + PROMO[promotion]
