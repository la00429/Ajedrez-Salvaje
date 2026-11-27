class_name MonteCarloEstimate
extends RefCounted

const Z_95 := 1.96

var samples: int
var mean: float
var std_dev: float
var minimum: float
var maximum: float


func _init(p_samples: int, p_mean: float, p_std_dev: float, p_minimum: float, p_maximum: float) -> void:
	samples = p_samples
	mean = p_mean
	std_dev = p_std_dev
	minimum = p_minimum
	maximum = p_maximum


func std_error() -> float:
	if samples == 0:
		return 0.0
	return std_dev / sqrt(float(samples))


func interval_low() -> float:
	return mean - Z_95 * std_error()


func interval_high() -> float:
	return mean + Z_95 * std_error()
