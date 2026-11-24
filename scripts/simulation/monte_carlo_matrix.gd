class_name MonteCarloMatrix
extends RefCounted

var events: Array[int] = []
var probabilities: Array[float] = []
var lower_bounds: Array[float] = []
var upper_bounds: Array[float] = []


func _init(p_events: Array[int], p_probabilities: Array[float]) -> void:
	assert(p_events.size() == p_probabilities.size(), "cada evento necesita una probabilidad")
	events = p_events
	probabilities = p_probabilities
	_build_ranges()


func event_for(r: float) -> int:
	for row in events.size():
		if r >= lower_bounds[row] and r < upper_bounds[row]:
			return events[row]
	return events[events.size() - 1]


func sample(source: RandomSource) -> int:
	return event_for(source.next_r())


func cumulative_probability(row: int) -> float:
	return upper_bounds[row]


func _build_ranges() -> void:
	var cumulative := 0.0
	for probability in probabilities:
		lower_bounds.append(cumulative)
		cumulative += probability
		upper_bounds.append(cumulative)
