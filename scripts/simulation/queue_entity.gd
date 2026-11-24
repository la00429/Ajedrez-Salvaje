class_name QueueEntity
extends RefCounted

var payload: Object
var source: StringName
var arrival_time: float
var service_start_time := -1.0
var service_time := 0.0
var departure_time := -1.0


func _init(p_payload: Object, p_source: StringName, p_arrival_time: float) -> void:
	payload = p_payload
	source = p_source
	arrival_time = p_arrival_time


func wait_time() -> float:
	return service_start_time - arrival_time


func system_time() -> float:
	return departure_time - arrival_time
