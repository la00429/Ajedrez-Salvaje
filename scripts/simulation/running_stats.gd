class_name RunningStats
extends RefCounted

var _count := 0
var _mean := 0.0
var _squared_deviations := 0.0
var _minimum := 0.0
var _maximum := 0.0


func add(value: float) -> void:
	_count += 1
	var delta := value - _mean
	_mean += delta / _count
	_squared_deviations += delta * (value - _mean)
	_track_extremes(value)


func to_estimate() -> MonteCarloEstimate:
	return MonteCarloEstimate.new(_count, _mean, _std_dev(), _minimum, _maximum)


func _std_dev() -> float:
	if _count < 2:
		return 0.0
	return sqrt(_squared_deviations / (_count - 1))


func _track_extremes(value: float) -> void:
	if _count == 1:
		_minimum = value
		_maximum = value
		return
	_minimum = minf(_minimum, value)
	_maximum = maxf(_maximum, value)
