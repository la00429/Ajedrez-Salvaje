class_name Flow
extends RefCounted

const POSITIVE := 1
const NEGATIVE := -1

var name: StringName
var polarity: int
var rate: float


func _init(p_name: StringName, p_polarity: int, p_rate: float) -> void:
	name = p_name
	polarity = p_polarity
	rate = maxf(p_rate, 0.0)


func signed_rate() -> float:
	return polarity * rate
