class_name SimulationEngine
extends RefCounted

enum Stream { CLIMATE = 1, HUNTER, NURSERY_PLAYER, NURSERY_RIVAL, EXCAVATOR }

const SIDES: Array[int] = [ChessPosition.PLAYER, ChessPosition.RIVAL]

var config: SimulationConfig
var level := 1
var hunter: Vector2i
var excavator := Board.INVALID
var ecosystems: Array[SideEcosystem] = []

var _root: RandomSource
var _water_system: WaterSystem
var _hunter_environment := HunterEnvironment.new()
var _hunter_agent := HunterAgent.new()
var _excavator_walk: RandomWalk
var _climate_source: RandomSource
var _hunter_source: RandomSource
var _excavator_source: RandomSource
var _nursery_sources: Array[RandomSource] = []


func _init(p_config: SimulationConfig = null, root_source: RandomSource = null) -> void:
	config = p_config if p_config else SimulationConfig.new()
	_root = root_source if root_source else MixedCongruential.new(config.random_seed)
	_water_system = WaterSystem.new(config)
	reset()


func reset() -> void:
	level = 1
	hunter = config.hunter_start
	excavator = Board.INVALID
	_excavator_walk = null
	_hunter_agent.reset()
	ecosystems = _new_ecosystems()
	_fork_streams()


func run_round(round_number: int, position: ChessPosition) -> RoundResult:
	var previous_level := level
	level = config.level_for_round(round_number)
	var result := RoundResult.new(round_number, level, _sample_climate(), level != previous_level)
	_run_ecosystems(result, position, float(round_number))
	result.hunter = _move_hunter(position)
	_move_excavator(result, position)
	return result


func enqueue_capture(side: int, payload: Object, round_number: int) -> bool:
	return nursery(side).arrive(payload, NurseryQueue.CAPTURE, float(round_number))


func enqueue_harvest(side: int, payload: Object, round_number: int) -> bool:
	return nursery(side).arrive(payload, NurseryQueue.HARVEST, float(round_number))


func verdict(position: ChessPosition, round_number: int) -> Verdict:
	return VictoryRules.evaluate(position, waters(), round_number, config.final_round)


func water(side: int) -> float:
	return ecosystems[side].water.level


func waters() -> Array[float]:
	var levels: Array[float] = []
	for ecosystem in ecosystems:
		levels.append(ecosystem.water.level)
	return levels


func nursery(side: int) -> NurseryServer:
	return ecosystems[side].nursery


func hunter_reward() -> float:
	return _hunter_agent.total_reward


func _new_ecosystems() -> Array[SideEcosystem]:
	var created: Array[SideEcosystem] = []
	for side in SIDES:
		var queue := NurseryQueue.new(config.nursery_capacity)
		var server := NurseryServer.new(queue, ExponentialService.new(config.nursery_service_rate))
		created.append(SideEcosystem.new(side, _water_system.new_stock(), server))
	return created


func _fork_streams() -> void:
	_climate_source = _root.fork(Stream.CLIMATE)
	_hunter_source = _root.fork(Stream.HUNTER)
	_nursery_sources.assign([_root.fork(Stream.NURSERY_PLAYER), _root.fork(Stream.NURSERY_RIVAL)])
	_excavator_source = MultiplicativeCongruential.new(_root.derive_seed(Stream.EXCAVATOR))


func _sample_climate() -> Climate.Type:
	return config.climate_matrix(level).sample(_climate_source) as Climate.Type


func _run_ecosystems(result: RoundResult, position: ChessPosition, clock: float) -> void:
	for ecosystem in ecosystems:
		var census := Census.of(position, ecosystem.side)
		result.water.append(_water_system.step(ecosystem.water, census, result.climate))
		var powered := ecosystem.water.level > config.nursery_water_threshold
		var source := _nursery_sources[ecosystem.side]
		result.regenerated.append(ecosystem.nursery.advance(clock, config.time_step, powered, source))
		result.queue_lengths.append(ecosystem.nursery.queue.length())


func _move_hunter(position: ChessPosition) -> HunterTransition:
	var observation := _hunter_environment.reset(position, hunter, _walkable(position, excavator))
	var transition := _hunter_environment.step(_hunter_agent.policy(observation, _hunter_source))
	_hunter_agent.receive(transition)
	hunter = transition.step.to
	return transition


func _move_excavator(result: RoundResult, position: ChessPosition) -> void:
	if not config.has_excavator(level):
		return
	if _excavator_walk == null:
		result.excavator_spawned = _spawn_excavator(position)
	if _excavator_walk == null:
		return
	result.excavator = _excavator_walk.step(_excavator_source, _walkable(position, hunter))
	excavator = result.excavator.to
	if result.excavator.has_moved():
		result.felled = result.excavator.from


func _spawn_excavator(position: ChessPosition) -> bool:
	var free := _free_squares(position)
	if free.is_empty():
		return false
	excavator = free[_excavator_source.next_int(free.size())]
	_excavator_walk = RandomWalk.new(excavator, config.excavator_edge_policy)
	return true


func _free_squares(position: ChessPosition) -> Array[Vector2i]:
	var free: Array[Vector2i] = []
	for index in 64:
		var coord := ChessPosition.to_coord(index)
		if position.squares[index] == ChessPosition.EMPTY and position.blocked[index] == 0 and coord != hunter:
			free.append(coord)
	return free


func _walkable(position: ChessPosition, occupied_by_other: Vector2i) -> Callable:
	return func(coord: Vector2i) -> bool:
		return Board.is_inside(coord) and position.blocked[ChessPosition.to_index(coord)] == 0 and coord != occupied_by_other
