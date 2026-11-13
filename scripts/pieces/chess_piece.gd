class_name ChessPiece
extends Node3D
## Pieza de Ajedrez Salvaje: su tipo, su bando y su modelo 3D.
##
## La pieza no decide cómo se mueve: eso lo calcula [MovementValidator] sobre
## una [ChessPosition]. Este nodo solo representa la pieza en el tablero.
## Al cambiar [member kind] (por ejemplo, al coronar) el modelo se reconstruye.
##
## Crear una pieza: [code]ChessPiece.create(ChessPiece.Kind.KNIGHT, ChessPiece.Team.PLAYER)[/code]
## y colocarla con [method Board.place_piece].

## Tipo de pieza. Los valores coinciden con los códigos de [ChessPosition].
enum Kind {
	PAWN = 1, ## Peón: frailejón.
	KNIGHT = 2, ## Caballo: venado de cola blanca.
	BISHOP = 3, ## Alfil: cóndor andino.
	ROOK = 4, ## Torre: oso de anteojos.
	QUEEN = 5, ## Dama: danta de montaña.
	KING = 6, ## Rey: frailejón Gran Abuelo.
	HUNTER = 16, ## Cazador furtivo: ocupante neutral, no es pieza de ajedrez.
}

## Bando. El jugador juega con "blancas" (filas 1 y 2) y empieza.
enum Team {
	PLAYER = 0, ## Jugador (blancas).
	RIVAL = 1, ## Fauna rival (negras).
	NEUTRAL = -1, ## Cazador u otros ocupantes sin bando.
}

const PieceModels := preload("res://scripts/pieces/piece_models.gd")

## Nombre de la especie de cada tipo.
const SPECIES := {
	Kind.PAWN: "Frailejón", Kind.KNIGHT: "Venado", Kind.BISHOP: "Cóndor", Kind.ROOK: "Oso de anteojos",
	Kind.QUEEN: "Danta", Kind.KING: "Gran Abuelo", Kind.HUNTER: "Cazador furtivo",
}
## Nombre de la pieza de ajedrez equivalente.
const CHESS_NAMES := {
	Kind.PAWN: "peón", Kind.KNIGHT: "caballo", Kind.BISHOP: "alfil", Kind.ROOK: "torre",
	Kind.QUEEN: "dama", Kind.KING: "rey", Kind.HUNTER: "neutral",
}

## Tipo de la pieza. Cambiarlo reconstruye el modelo (coronación).
@export var kind: Kind = Kind.PAWN:
	set(value):
		kind = value
		_rebuild()
## Bando de la pieza.
@export var side: Team = Team.PLAYER:
	set(value):
		side = value
		_rebuild()

var _model: Node3D


## Crea una pieza lista para colocar en el tablero.
static func create(p_kind: Kind, p_side: Team) -> ChessPiece:
	var piece := ChessPiece.new()
	piece.kind = p_kind
	piece.side = p_side if p_kind != Kind.HUNTER else Team.NEUTRAL
	return piece


func _ready() -> void:
	_rebuild()


## Nombre de la especie: "Venado", "Cóndor"...
func species_name() -> String:
	return SPECIES.get(kind, "Pieza")


## Nombre para mostrar: "Venado (jugador)", "Cazador furtivo"...
func display_name() -> String:
	if side == Team.NEUTRAL:
		return species_name()
	return "%s (%s)" % [species_name(), "jugador" if side == Team.PLAYER else "rival"]


func _rebuild() -> void:
	if not is_inside_tree() and _model == null:
		return # se construye en _ready
	if _model:
		remove_child(_model)
		_model.queue_free()
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model, false, Node.INTERNAL_MODE_FRONT)
	var height := PieceModels.build(_model, kind, side)
	# Las figuras miran hacia el bando contrario.
	if side == Team.RIVAL:
		_model.rotation.y = PI
	# Altura de clic para el tablero, en casillas (incluye la escala de la pieza).
	var base_scale: Vector3 = get_meta(&"board_base_scale", scale)
	set_meta(&"board_pick_height", height * base_scale.y)
