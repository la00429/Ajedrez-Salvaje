class_name Verdict
extends RefCounted

enum Reason {
	NONE,
	CHECKMATE,
	KING_LOST,
	STALEMATE,
	WATER_COLLAPSE,
	BOTH_COLLAPSED,
	FINAL_WATER,
	FINAL_MATERIAL,
	FINAL_DRAW,
}

const NO_WINNER := -1

var reason: Reason
var winner: int


func _init(p_reason: Reason = Reason.NONE, p_winner: int = NO_WINNER) -> void:
	reason = p_reason
	winner = p_winner


func is_finished() -> bool:
	return reason != Reason.NONE


func is_draw() -> bool:
	return is_finished() and winner == NO_WINNER
