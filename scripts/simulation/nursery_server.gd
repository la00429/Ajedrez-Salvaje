class_name NurseryServer
extends RefCounted

enum State { OFF, ON }

var queue: NurseryQueue
var service: ExponentialService
var state := State.ON

var _current: QueueEntity
var _remaining := 0.0
var _arrivals := 0
var _departures := 0
var _elapsed := 0.0
var _busy_time := 0.0
var _total_system_time := 0.0


func _init(p_queue: NurseryQueue, p_service: ExponentialService) -> void:
	queue = p_queue
	service = p_service


func arrive(payload: Object, source: StringName, clock: float) -> bool:
	var accepted := queue.enqueue(payload, source, clock)
	if accepted:
		_arrivals += 1
	return accepted


func advance(clock: float, dt: float, powered: bool, source: RandomSource) -> QueueEntity:
	_elapsed += dt
	state = State.ON if powered else State.OFF
	if state == State.OFF:
		return null
	_start_next(clock, source)
	return _serve(clock, dt)


func clear() -> void:
	queue.clear()
	state = State.ON
	_current = null
	_remaining = 0.0
	_arrivals = 0
	_departures = 0
	_elapsed = 0.0
	_busy_time = 0.0
	_total_system_time = 0.0


func is_busy() -> bool:
	return _current != null


func departures() -> int:
	return _departures


func arrival_rate() -> float:
	return _per_time(_arrivals)


func throughput() -> float:
	return _per_time(_departures)


func utilization() -> float:
	return _busy_time / _elapsed if _elapsed > 0.0 else 0.0


func average_system_time() -> float:
	return _total_system_time / _departures if _departures > 0 else 0.0


func _start_next(clock: float, source: RandomSource) -> void:
	if _current != null or queue.is_empty():
		return
	_current = queue.begin_service(clock)
	_current.service_time = service.sample(source)
	_remaining = _current.service_time


func _serve(clock: float, dt: float) -> QueueEntity:
	if _current == null:
		return null
	var worked := minf(dt, _remaining)
	_busy_time += worked
	_remaining -= dt
	if _remaining > 0.0:
		return null
	return _depart(clock + worked)


func _depart(departure_time: float) -> QueueEntity:
	var entity := _current
	entity.departure_time = departure_time
	_total_system_time += entity.system_time()
	_departures += 1
	_current = null
	return entity


func _per_time(count: int) -> float:
	return count / _elapsed if _elapsed > 0.0 else 0.0
