class_name RoundResult
extends RefCounted

var round_number: int
var level: int
var level_started: bool
var climate: Climate.Type
var water: Array[StockStep] = []
var regenerated: Array[QueueEntity] = []
var queue_lengths: Array[int] = []
var hunter: HunterTransition
var excavator: WalkStep
var excavator_spawned := false
var felled := Board.INVALID


func _init(p_round_number: int, p_level: int, p_climate: Climate.Type, p_level_started: bool) -> void:
	round_number = p_round_number
	level = p_level
	climate = p_climate
	level_started = p_level_started


func climate_label() -> String:
	return Climate.label(climate)


func water_percent(side: int) -> float:
	return water[side].level_after


func collapsed_sides() -> Array[int]:
	var sides: Array[int] = []
	for side in water.size():
		if water[side].is_collapsed():
			sides.append(side)
	return sides


func to_dictionary() -> Dictionary:
	return {
		"round": round_number,
		"level": level,
		"climate": climate_label(),
		"water": water.map(func(step: StockStep) -> float: return step.level_after),
		"queue_lengths": queue_lengths.duplicate(),
		"regenerated": regenerated.map(func(entity: QueueEntity) -> StringName: return entity.source if entity else &""),
		"hunter_from": hunter.step.from if hunter else Board.INVALID,
		"hunter_to": hunter.step.to if hunter else Board.INVALID,
		"excavator_to": excavator.to if excavator else Board.INVALID,
		"felled": felled,
	}
