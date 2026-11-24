class_name Stock
extends RefCounted

var level: float
var minimum: float
var maximum: float


func _init(p_level: float, p_minimum: float, p_maximum: float) -> void:
	minimum = p_minimum
	maximum = p_maximum
	level = clampf(p_level, minimum, maximum)


func integrate(flows: Array[Flow], dt: float) -> StockStep:
	var before := level
	var unbounded := level + net_rate(flows) * dt
	level = clampf(unbounded, minimum, maximum)
	return StockStep.new(before, level, flows, dt, level - unbounded)


func is_depleted() -> bool:
	return level <= minimum


static func net_rate(flows: Array[Flow]) -> float:
	var total := 0.0
	for flow in flows:
		total += flow.signed_rate()
	return total
