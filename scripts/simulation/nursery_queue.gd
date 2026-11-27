class_name NurseryQueue
extends RefCounted

const CAPTURE := &"capture"
const HARVEST := &"harvest"

var capacity: int

var _entities: Array[QueueEntity] = []
var _started := 0
var _rejected := 0
var _total_wait := 0.0


func _init(p_capacity: int) -> void:
	capacity = p_capacity


func enqueue(payload: Object, source: StringName, arrival_time: float) -> bool:
	assert(source == CAPTURE or source == HARVEST, "origen de vivero inválido")
	if is_full():
		_rejected += 1
		return false
	_entities.append(QueueEntity.new(payload, source, arrival_time))
	return true


func begin_service(clock: float) -> QueueEntity:
	if is_empty():
		return null
	var entity: QueueEntity = _entities.pop_front()
	entity.service_start_time = maxf(clock, entity.arrival_time)
	_started += 1
	_total_wait += entity.wait_time()
	return entity


func clear() -> void:
	_entities.clear()
	_started = 0
	_rejected = 0
	_total_wait = 0.0


func length() -> int:
	return _entities.size()


func count_from(source: StringName) -> int:
	return _entities.filter(func(entity: QueueEntity) -> bool: return entity.source == source).size()


func rejected_count() -> int:
	return _rejected


func started_count() -> int:
	return _started


func average_wait() -> float:
	return _total_wait / _started if _started > 0 else 0.0


func is_empty() -> bool:
	return _entities.is_empty()


func is_full() -> bool:
	return _entities.size() >= capacity
