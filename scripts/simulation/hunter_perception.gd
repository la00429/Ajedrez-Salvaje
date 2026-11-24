class_name HunterPerception
extends RefCounted

var nearest_pieces: Array[Vector2i]
var distance: int


func _init(p_nearest_pieces: Array[Vector2i], p_distance: int) -> void:
	nearest_pieces = p_nearest_pieces
	distance = p_distance


func sees_prey() -> bool:
	return not nearest_pieces.is_empty()
