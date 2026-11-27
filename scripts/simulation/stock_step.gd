class_name StockStep
extends RefCounted

var level_before: float
var level_after: float
var flows: Array[Flow]
var dt: float
var adjustment: float


func _init(p_level_before: float, p_level_after: float, p_flows: Array[Flow], p_dt: float, p_adjustment: float) -> void:
	level_before = p_level_before
	level_after = p_level_after
	flows = p_flows
	dt = p_dt
	adjustment = p_adjustment


func net_rate() -> float:
	return Stock.net_rate(flows)


func delta() -> float:
	return level_after - level_before


func rate_of(flow_name: StringName) -> float:
	for flow in flows:
		if flow.name == flow_name:
			return flow.rate
	return 0.0


func is_collapsed() -> bool:
	return level_after <= 0.0
