class_name HunterObservation
extends RefCounted

var hunter: Vector2i
var pieces: Array[Vector2i]
var legal_actions: Array[Vector2i]


func _init(p_hunter: Vector2i, p_pieces: Array[Vector2i], p_legal_actions: Array[Vector2i]) -> void:
	hunter = p_hunter
	pieces = p_pieces
	legal_actions = p_legal_actions
