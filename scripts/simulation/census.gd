class_name Census
extends RefCounted

const PLANT_KINDS: Array[int] = [ChessPiece.Kind.PAWN]
const ANIMAL_KINDS: Array[int] = [ChessPiece.Kind.KNIGHT, ChessPiece.Kind.BISHOP, ChessPiece.Kind.ROOK, ChessPiece.Kind.QUEEN]

var plants: int
var animals: int


func _init(p_plants: int, p_animals: int) -> void:
	plants = maxi(p_plants, 0)
	animals = maxi(p_animals, 0)


static func of(position: ChessPosition, side: int) -> Census:
	return Census.new(_count(position, side, PLANT_KINDS), _count(position, side, ANIMAL_KINDS))


static func _count(position: ChessPosition, side: int, kinds: Array[int]) -> int:
	var total := 0
	for kind in kinds:
		total += position.count(kind, side)
	return total
