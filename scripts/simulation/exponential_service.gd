class_name ExponentialService
extends RefCounted

var rate: float


func _init(p_rate: float) -> void:
	assert(p_rate > 0.0, "la tasa de servicio debe ser positiva")
	rate = p_rate


func sample(source: RandomSource) -> float:
	return -log(1.0 - source.next_r()) / rate


func mean() -> float:
	return 1.0 / rate
