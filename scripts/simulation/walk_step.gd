class_name WalkStep
extends RefCounted

var from: Vector2i
var to: Vector2i


func _init(p_from: Vector2i, p_to: Vector2i) -> void:
	from = p_from
	to = p_to


func has_moved() -> bool:
	return from != to
