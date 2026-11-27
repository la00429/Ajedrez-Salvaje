extends SceneTree

const ScriptedSource := preload("res://tests/simulation/scripted_source.gd")
const PLAYER := ChessPosition.PLAYER
const RIVAL := ChessPosition.RIVAL
const FOOLS_MATE := "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"
const STALEMATE := "7k/5Q2/6K1/8/8/8/8/8 b - - 0 1"
const NO_PLAYER_KING := "4k3/8/8/8/8/8/8/8 w - - 0 1"
const PLAYER_WITHOUT_PAWNS := "rnbqkbnr/pppppppp/8/8/8/8/8/RNBQKBNR w KQkq - 0 1"
const PLAYER_EXTRA_ROOK := "4k3/8/8/8/8/8/8/R3K3 w - - 0 1"
const KINGS_ONLY := "4k3/8/8/8/8/8/8/4K3 w - - 0 1"

var _checks := 0
var _failures := 0


func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	_test_mixed_congruential()
	_test_multiplicative_congruential()
	_test_forks()
	_test_monte_carlo_matrix()
	_test_monte_carlo_estimate()
	_test_system_dynamics()
	_test_document_game()
	_test_queue()
	_test_server()
	_test_mm1_theory()
	_test_random_walk()
	_test_hunter_agent()
	_test_levels()
	_test_victory_rules()
	_test_engine()
	print("\n%d comprobaciones, %d fallidas" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("  FALLA: " + message)


func _section(title: String) -> void:
	print("- " + title)


func _scripted(values: Array) -> RandomSource:
	return ScriptedSource.new(values)


func _draw(source: RandomSource, count: int) -> Array:
	var values := []
	for index in count:
		values.append(source.next_r())
	return values


func _mean_of(source: RandomSource, count: int) -> float:
	var total := 0.0
	for value in _draw(source, count):
		total += value
	return total / count


func _in_unit_range(source: RandomSource) -> bool:
	return _draw(source, 2000).all(func(r: float) -> bool: return r >= 0.0 and r < 1.0)


func _test_mixed_congruential() -> void:
	_section("Congruencia mixta")
	_check(MixedCongruential.new(1).next_x() == 1015568748, "x1 = (a * x0 + c) mod m con x0 = 1")
	_check(_draw(MixedCongruential.new(7), 50) == _draw(MixedCongruential.new(7), 50), "misma semilla, misma secuencia")
	_check(_draw(MixedCongruential.new(7), 50) != _draw(MixedCongruential.new(8), 50), "semillas distintas, secuencias distintas")
	_check(_in_unit_range(MixedCongruential.new(3)), "Ri = xi / m en [0, 1)")
	_check(absf(_mean_of(MixedCongruential.new(11), 10000) - 0.5) < 0.02, "media de Ri cercana a 0.5")
	var m := MixedCongruential.DEFAULT_MODULUS
	_check(MixedCongruential.satisfies_hull_dobell(MixedCongruential.DEFAULT_MULTIPLIER, MixedCongruential.DEFAULT_INCREMENT, m), "los parámetros por defecto cumplen Hull-Dobell")
	_check(not MixedCongruential.satisfies_hull_dobell(MixedCongruential.DEFAULT_MULTIPLIER, 2, m), "c no coprimo con m incumple Hull-Dobell")
	_check(not MixedCongruential.satisfies_hull_dobell(3, MixedCongruential.DEFAULT_INCREMENT, m), "a - 1 no múltiplo de 4 incumple Hull-Dobell")
	_check(_full_period(MixedCongruential.new(0, 5, 3, 16)) == 16, "con Hull-Dobell el período es m")
	_check(not _scripted([0.0]).chance(0.0) and _scripted([0.999]).chance(1.0), "probabilidades 0 y 1")


func _full_period(generator: MixedCongruential) -> int:
	var first := generator.next_x()
	var period := 1
	while generator.next_x() != first:
		period += 1
	return period


func _test_multiplicative_congruential() -> void:
	_section("Congruencia multiplicativa (Lehmer)")
	var lehmer := MultiplicativeCongruential.new(1)
	_check(lehmer.next_x() == 16807 and lehmer.next_x() == 282475249, "x1 = a * x0 mod m y x2")
	_check(_ten_thousandth(MultiplicativeCongruential.new(1)) == 1043618065, "x10000 de la prueba de Park y Miller")
	_check(not MultiplicativeCongruential.is_valid_seed(0, 2147483647), "la semilla 0 no es válida")
	_check(MultiplicativeCongruential.new(0).x0 == 1, "una semilla inválida se corrige")
	_check(MultiplicativeCongruential.new(5, 3, 10).x0 == 7, "la semilla se ajusta a un coprimo de m")
	_check(_in_unit_range(MultiplicativeCongruential.new(9)), "Ri en [0, 1)")
	_check(absf(_mean_of(MultiplicativeCongruential.new(13), 10000) - 0.5) < 0.02, "media de Ri cercana a 0.5")


func _ten_thousandth(generator: MultiplicativeCongruential) -> int:
	var value := 0
	for index in 10000:
		value = generator.next_x()
	return value


func _test_forks() -> void:
	_section("Subgeneradores")
	var root := MixedCongruential.new(99)
	var before := _draw(root.fork(1), 20)
	_draw(root, 500)
	_check(_draw(root.fork(1), 20) == before, "el fork no depende de lo ya consumido")
	_check(_draw(root.fork(1), 20) != _draw(root.fork(2), 20), "flujos distintos difieren")
	var untouched := root.fork(3)
	_draw(root.fork(3), 100)
	_check(_draw(untouched, 5) == _draw(root.fork(3), 5), "consumir un fork no altera otro")
	var lehmer := MultiplicativeCongruential.new(4)
	_check(_draw(lehmer.fork(1), 10) == _draw(lehmer.fork(1), 10) and _draw(lehmer.fork(1), 10) != _draw(lehmer.fork(2), 10), "forks de Lehmer reproducibles y distintos")


func _climate(level: int = 1) -> MonteCarloMatrix:
	return SimulationConfig.new().climate_matrix(level)


func _test_monte_carlo_matrix() -> void:
	_section("Matriz de Monte Carlo")
	var matrix := _climate()
	_check(is_equal_approx(matrix.cumulative_probability(0), 0.70) and is_equal_approx(matrix.cumulative_probability(2), 0.98), "probabilidades acumuladas [0.70, 0.85, 0.98, 1.00]")
	_check(matrix.event_for(0.41285) == Climate.Type.STABLE, "0.41285 cae en [0, 0.70): estable")
	_check(matrix.event_for(0.74120) == Climate.Type.RAIN, "0.74120 cae en [0.70, 0.85): lluvia")
	_check(matrix.event_for(0.92340) == Climate.Type.FROST, "0.92340 cae en [0.85, 0.98): helada")
	_check(matrix.event_for(0.99) == Climate.Type.CATASTROPHE, "0.99 cae en [0.98, 1.00): catástrofe")
	_check(_climate(2).event_for(0.80) == Climate.Type.FROST, "en clima severo 0.80 ya es helada")
	_check(_frequencies_converge(matrix), "las frecuencias convergen a las probabilidades")


func _frequencies_converge(matrix: MonteCarloMatrix) -> bool:
	var source := MixedCongruential.new(17)
	var counts := {}
	for index in 20000:
		var event := matrix.sample(source)
		counts[event] = counts.get(event, 0) + 1
	for row in matrix.events.size():
		if absf(counts.get(matrix.events[row], 0) / 20000.0 - matrix.probabilities[row]) > 0.015:
			return false
	return true


func _test_monte_carlo_estimate() -> void:
	_section("Monte Carlo: agregación de resultados")
	var model := MonteCarloModel.new()
	var four := func(_source: RandomSource) -> float: return 4.0
	var constant := model.estimate(four, 30, MixedCongruential.new(1))
	_check(constant.samples == 30 and constant.mean == 4.0 and constant.std_dev == 0.0, "ensayo constante")
	_check(model.estimate(four, 0, MixedCongruential.new(1)).samples == 0, "cero réplicas")
	var indicator := func(source: RandomSource) -> float: return 1.0 if source.chance(0.3) else 0.0
	var estimate := model.estimate(indicator, 2000, MixedCongruential.new(5))
	_check(absf(estimate.mean - 0.3) < 0.05, "estima una probabilidad conocida")
	_check(estimate.interval_low() < 0.3 and 0.3 < estimate.interval_high(), "el intervalo del 95 % contiene el valor real")
	_check(model.estimate(indicator, 10000, MixedCongruential.new(5)).std_error() < model.estimate(indicator, 100, MixedCongruential.new(5)).std_error(), "el error baja como 1 / sqrt(N)")


func _test_system_dynamics() -> void:
	_section("Dinámica de sistemas")
	var config := SimulationConfig.new()
	var system := WaterSystem.new(config)
	var census := Census.new(8, 7)
	var flows := system.flows(census, Climate.Type.STABLE)
	_check(flows.filter(func(flow: Flow) -> bool: return flow.polarity == Flow.POSITIVE).size() == 2, "dos flujos de entrada (+)")
	_check(flows.filter(func(flow: Flow) -> bool: return flow.polarity == Flow.NEGATIVE).size() == 3, "tres flujos de salida (-)")
	var stock := system.new_stock()
	var stable := system.step(stock, census, Climate.Type.STABLE)
	_check(is_equal_approx(stable.rate_of(WaterSystem.CONDENSATION), 1.6) and is_equal_approx(stable.rate_of(WaterSystem.CONSUMPTION), 0.6), "condensación 1.6 y consumo 0.6")
	_check(is_equal_approx(stable.net_rate(), 0.0), "flujo neto nulo en clima estable")
	_check(is_equal_approx(system.step(Stock.new(50.0, 0.0, 100.0), census, Climate.Type.FROST).net_rate(), -2.0), "la helada triplica la evaporación")
	_check(system.step(Stock.new(99.5, 0.0, 100.0), census, Climate.Type.RAIN).level_after == 100.0, "el nivel no supera el máximo")
	var dry := Stock.new(1.0, 0.0, 100.0)
	_check(system.step(dry, census, Climate.Type.CATASTROPHE).is_collapsed() and dry.is_depleted(), "el nivel no baja de cero")
	var many := system.step(Stock.new(50.0, 0.0, 100.0), census, Climate.Type.STABLE).level_after
	var few := system.step(Stock.new(50.0, 0.0, 100.0), Census.new(2, 7), Climate.Type.STABLE).level_after
	_check(few < many, "realimentación: menos plantas, menos agua")
	_check(_euler_holds(system), "Euler: A(t+dt) = A(t) + dt * flujo neto (+ ajuste por límites)")


func _euler_holds(system: WaterSystem) -> bool:
	for climate in Climate.Type.values():
		var step := system.step(Stock.new(97.0, 0.0, 100.0), Census.new(8, 7), climate)
		if not is_equal_approx(step.level_after, step.level_before + step.net_rate() * step.dt + step.adjustment):
			return false
	return true


func _test_document_game() -> void:
	_section("Partida de ejemplo del documento de preproducción")
	var system := WaterSystem.new(SimulationConfig.new())
	var stock := system.new_stock()
	var rolls := [0.41285, 0.92340, 0.21050, 0.74120]
	var expected := [100.0, 98.0, 98.0, 100.0]
	for turn in rolls.size():
		var climate := _climate().event_for(rolls[turn]) as Climate.Type
		system.step(stock, Census.new(8, 7), climate)
		_check(is_equal_approx(stock.level, expected[turn]), "A(%d) = %.1f" % [turn + 1, expected[turn]])


func _test_queue() -> void:
	_section("Sistema de espera: cola")
	var queue := NurseryQueue.new(3)
	_check(queue.is_empty() and queue.begin_service(0.0) == null, "cola vacía no atiende")
	var first := RefCounted.new()
	queue.enqueue(first, NurseryQueue.CAPTURE, 1.0)
	queue.enqueue(RefCounted.new(), NurseryQueue.HARVEST, 2.0)
	_check(queue.count_from(NurseryQueue.CAPTURE) == 1 and queue.count_from(NurseryQueue.HARVEST) == 1, "captura y cosecha separadas")
	var entity := queue.begin_service(4.0)
	_check(entity.payload == first and is_equal_approx(entity.wait_time(), 3.0), "FIFO; espera = inicio de servicio - llegada")
	queue.enqueue(RefCounted.new(), NurseryQueue.CAPTURE, 5.0)
	queue.enqueue(RefCounted.new(), NurseryQueue.CAPTURE, 5.0)
	_check(queue.is_full() and not queue.enqueue(RefCounted.new(), NurseryQueue.CAPTURE, 6.0) and queue.rejected_count() == 1, "capacidad limitada")


func _new_server(rate: float) -> NurseryServer:
	return NurseryServer.new(NurseryQueue.new(8), ExponentialService.new(rate))


func _test_server() -> void:
	_section("Sistema de espera: servidor exponencial")
	_check(is_equal_approx(ExponentialService.new(1.0).sample(_scripted([1.0 - exp(-1.0)])), 1.0), "t = -ln(1 - U) / mu")
	_check(_exponential_mean_ok(), "media del servicio = 1 / mu")
	var server := _new_server(0.5)
	server.arrive(RefCounted.new(), NurseryQueue.HARVEST, 0.0)
	var departed := _advance_until_departure(server, 0.9)
	var service_time := -log(0.1) / 0.5
	_check(departed != null and is_equal_approx(departed.service_start_time, 1.0), "el servicio inicia en el reloj 1")
	_check(is_equal_approx(departed.departure_time, 1.0 + service_time), "salida = inicio + tiempo de servicio")
	_check(is_equal_approx(departed.system_time(), departed.wait_time() + departed.service_time), "tiempo en sistema = espera + servicio")
	_check(is_equal_approx(server.utilization(), service_time / 5.0), "utilización = tiempo ocupado / tiempo transcurrido")
	var off := _new_server(1.0)
	off.arrive(RefCounted.new(), NurseryQueue.CAPTURE, 0.0)
	_check(off.advance(1.0, 1.0, false, _scripted([0.0])) == null and off.state == NurseryServer.State.OFF and off.queue.length() == 1, "servidor apagado no atiende")
	var single := _new_server(0.5)
	single.arrive(RefCounted.new(), NurseryQueue.CAPTURE, 0.0)
	single.arrive(RefCounted.new(), NurseryQueue.CAPTURE, 0.0)
	single.advance(1.0, 1.0, true, _scripted([0.9]))
	_check(single.is_busy() and single.queue.length() == 1 and is_equal_approx(single.arrival_rate(), 2.0), "un servidor: la segunda espera; lambda medido")


func _exponential_mean_ok() -> bool:
	var service := ExponentialService.new(0.5)
	var source := MixedCongruential.new(3)
	var total := 0.0
	for index in 20000:
		total += service.sample(source)
	return absf(total / 20000.0 - service.mean()) < 0.1


func _advance_until_departure(server: NurseryServer, roll: float) -> QueueEntity:
	var source := _scripted([roll])
	for clock in range(1, 20):
		var departed := server.advance(float(clock), 1.0, true, source)
		if departed:
			return departed
	return null


func _test_mm1_theory() -> void:
	_section("Teoría M/M/1")
	_check(is_equal_approx(MM1Theory.utilization(0.25, 0.5), 0.5), "rho = lambda / mu")
	_check(is_equal_approx(MM1Theory.system_length(0.25, 0.5), 1.0) and is_equal_approx(MM1Theory.queue_length(0.25, 0.5), 0.5), "L y Lq")
	_check(is_equal_approx(MM1Theory.system_time(0.25, 0.5), 4.0) and is_equal_approx(MM1Theory.queue_wait(0.25, 0.5), 2.0), "W y Wq")
	_check(not MM1Theory.has_steady_state(0.5, 0.5) and MM1Theory.queue_length(0.6, 0.5) == INF, "sin estado estacionario si rho >= 1")


func _test_random_walk() -> void:
	_section("Caminata aleatoria 2D")
	_check(RandomWalk.increment_for(0.12540) == Vector2i(0, 1) and RandomWalk.increment_for(0.30) == Vector2i(0, -1), "[0, .25) Norte y [.25, .5) Sur")
	_check(RandomWalk.increment_for(0.61200) == Vector2i(1, 0) and RandomWalk.increment_for(0.82410) == Vector2i(-1, 0), "[.5, .75) Este y [.75, 1) Oeste")
	var walk := RandomWalk.new(Vector2i(3, 3), RandomWalk.EdgePolicy.STAY)
	var step := walk.step(_scripted([0.82410]))
	_check(step.to == Vector2i(2, 3) and walk.position == Vector2i(2, 3) and walk.step_count == 1, "x(n+1) = x(n) + s(n): d4 a c4")
	_check(walk.displacement() == Vector2i(-1, 0) and walk.squared_distance() == 1, "desplazamiento desde el origen")
	_check(not RandomWalk.new(Vector2i(0, 0), RandomWalk.EdgePolicy.STAY).step(_scripted([0.30])).has_moved(), "borde con STAY: se queda")
	var corner := RandomWalk.new(Vector2i(0, 0), RandomWalk.EdgePolicy.REDRAW)
	_check(corner.step(_scripted([0.9])).to == Vector2i(1, 0), "borde con REDRAW: sortea entre direcciones válidas")
	_check(_increments_uniform(), "cada incremento con probabilidad cercana a 1/4")
	_check(_plane_statistics_hold(), "en el plano E[X] ~ 0 y E[X^2 + Y^2] ~ n")
	_check(_stays_inside_and_moves(), "en el tablero nunca sale y con REDRAW siempre se mueve")


func _anywhere(_coord: Vector2i) -> bool:
	return true


func _increments_uniform() -> bool:
	var walk := RandomWalk.new(Vector2i.ZERO, RandomWalk.EdgePolicy.STAY)
	var source := MultiplicativeCongruential.new(21)
	var counts := {}
	for index in 8000:
		var step := walk.step(source, _anywhere)
		var increment := step.to - step.from
		counts[increment] = counts.get(increment, 0) + 1
	return counts.size() == 4 and counts.values().all(func(count: int) -> bool: return absf(count / 8000.0 - 0.25) < 0.03)


func _plane_statistics_hold() -> bool:
	var steps := 50
	var walks := 2000
	var source := MultiplicativeCongruential.new(7)
	var sum_x := 0.0
	var sum_squared := 0.0
	for index in walks:
		var walk := RandomWalk.new(Vector2i.ZERO, RandomWalk.EdgePolicy.STAY)
		for step in steps:
			walk.step(source, _anywhere)
		sum_x += walk.position.x
		sum_squared += walk.squared_distance()
	return absf(sum_x / walks) < 0.5 and absf(sum_squared / walks - steps) < 5.0


func _stays_inside_and_moves() -> bool:
	var walk := RandomWalk.new(Vector2i(0, 0), RandomWalk.EdgePolicy.REDRAW)
	var source := MultiplicativeCongruential.new(4)
	for index in 300:
		var step := walk.step(source)
		if not Board.is_inside(step.to) or not step.has_moved():
			return false
	return true


func _position_with(pieces: Array[Vector2i]) -> ChessPosition:
	var position := ChessPosition.new()
	for coord in pieces:
		position.set_piece(coord, ChessPosition.encode(ChessPiece.Kind.PAWN, PLAYER))
	return position


func _inside(coord: Vector2i) -> bool:
	return Board.is_inside(coord)


func _test_hunter_agent() -> void:
	_section("Agente cazador")
	var environment := HunterEnvironment.new()
	var agent := HunterAgent.new()
	var origin := Vector2i(0, 0)
	var observation := environment.reset(_position_with([Vector2i(0, 3), Vector2i(5, 5)]), origin, _inside)
	_check(observation.pieces.size() == 2 and observation.legal_actions.size() == 3, "observa las piezas y sus acciones legales en la esquina")
	var perception := agent.perceive(observation)
	_check(perception.nearest_pieces.size() == 1 and perception.nearest_pieces[0] == Vector2i(0, 3) and perception.distance == 3, "percibe la pieza más cercana")
	_check(agent.policy(observation, _scripted([0.0])) == Vector2i(0, 1) and agent.target == Vector2i(0, 3), "la política avanza hacia ella y la recuerda")
	var adjacent := environment.reset(_position_with([Vector2i(1, 0)]), origin, _inside)
	var transition := environment.step(agent.policy(adjacent, _scripted([0.0])))
	agent.receive(transition)
	_check(transition.step.to == Vector2i(1, 0) and transition.reward == 1.0 and transition.terminated, "pisa la pieza: recompensa 1 y episodio terminado")
	_check(agent.total_reward == 1.0, "acumula la recompensa del episodio")
	var empty := environment.reset(ChessPosition.new(), origin, _inside)
	_check(HunterAgent.new().policy(empty, _scripted([0.0])) == HunterAgent.STAY, "sin piezas se queda quieto")
	var walls := func(coord: Vector2i) -> bool: return coord != Vector2i(2, 1) and coord != Vector2i(1, 2)
	var walled := environment.reset(_position_with([Vector2i(2, 2)]), Vector2i(1, 1), walls)
	_check(HunterAgent.new().policy(walled, _scripted([0.0])) == HunterAgent.STAY, "si las casillas que acercan están bloqueadas, espera")
	_check(_always_closes_in(), "cada paso reduce en 1 la distancia a la presa")


func _always_closes_in() -> bool:
	var source := MultiplicativeCongruential.new(31)
	for trial in 200:
		var hunter := Vector2i(source.next_int(8), source.next_int(8))
		var piece := Vector2i(source.next_int(8), source.next_int(8))
		if hunter == piece:
			continue
		var environment := HunterEnvironment.new()
		var observation := environment.reset(_position_with([piece]), hunter, _inside)
		var step := environment.step(HunterAgent.new().policy(observation, source)).step
		if Board.manhattan_distance(step.to, piece) != Board.manhattan_distance(hunter, piece) - 1:
			return false
	return true


func _test_levels() -> void:
	_section("Niveles por rondas")
	var config := SimulationConfig.new()
	_check(config.level_for_round(1) == 1 and config.level_for_round(10) == 1, "rondas 1 a 10: nivel 1")
	_check(config.level_for_round(11) == 2 and config.level_for_round(21) == 3 and config.level_for_round(99) == 3, "nivel 2 desde la 11 y 3 desde la 21")
	_check(not config.has_excavator(2) and config.has_excavator(3), "la retroexcavadora aparece en el nivel 3")
	_check(config.climate_matrix(1).probabilities[2] < config.climate_matrix(2).probabilities[2], "el clima se endurece en el nivel 2")


func _waters(player: float, rival: float) -> Array[float]:
	var levels: Array[float] = [player, rival]
	return levels


func _test_victory_rules() -> void:
	_section("Condiciones de victoria")
	var start := ChessPosition.initial()
	var mate := VictoryRules.evaluate(ChessPosition.from_fen(FOOLS_MATE), _waters(50, 50), 3, 30)
	_check(mate.reason == Verdict.Reason.CHECKMATE and mate.winner == RIVAL, "jaque mate")
	var lost := VictoryRules.evaluate(ChessPosition.from_fen(NO_PLAYER_KING), _waters(50, 50), 3, 30)
	_check(lost.reason == Verdict.Reason.KING_LOST and lost.winner == RIVAL, "rey destruido por un desestabilizador")
	_check(VictoryRules.evaluate(ChessPosition.from_fen(STALEMATE), _waters(50, 50), 3, 30).is_draw(), "ahogado: tablas")
	var dry := VictoryRules.evaluate(start, _waters(0, 40), 5, 30)
	_check(dry.reason == Verdict.Reason.WATER_COLLAPSE and dry.winner == RIVAL, "colapso hídrico: gana el otro")
	var both := VictoryRules.evaluate(start, _waters(0, 0), 5, 30)
	_check(both.reason == Verdict.Reason.BOTH_COLLAPSED and both.is_draw(), "colapso simultáneo: tablas")
	_check(not VictoryRules.evaluate(start, _waters(60, 40), 29, 30).is_finished(), "antes de la ronda final sigue la partida")
	var final_water := VictoryRules.evaluate(start, _waters(60, 40), 30, 30)
	_check(final_water.reason == Verdict.Reason.FINAL_WATER and final_water.winner == PLAYER, "ronda final: gana quien tenga más agua")
	var final_material := VictoryRules.evaluate(ChessPosition.from_fen(PLAYER_EXTRA_ROOK), _waters(50, 50), 30, 30)
	_check(final_material.reason == Verdict.Reason.FINAL_MATERIAL and final_material.winner == PLAYER, "empate de agua: decide el material")
	_check(VictoryRules.evaluate(ChessPosition.from_fen(KINGS_ONLY), _waters(50, 50), 30, 30).reason == Verdict.Reason.FINAL_DRAW, "empate total: tablas")


func _test_engine() -> void:
	_section("Motor de simulación")
	_check(_run_rounds(MixedCongruential.new(21), 25) == _run_rounds(MixedCongruential.new(21), 25), "misma semilla, mismas rondas")
	_check(_run_rounds(MixedCongruential.new(21), 25) != _run_rounds(MixedCongruential.new(22), 25), "semilla distinta, rondas distintas")
	_check(_climates(ChessPosition.initial()) == _climates(ChessPosition.from_fen(PLAYER_WITHOUT_PAWNS)), "el clima no depende de los demás modelos")
	_test_engine_water()
	_test_engine_levels()
	_test_engine_hunter()
	_test_engine_nursery()
	_test_engine_reset()


func _run_rounds(source: RandomSource, rounds: int) -> Array:
	var engine := SimulationEngine.new(null, source)
	var snapshots := []
	for round_number in range(1, rounds + 1):
		snapshots.append(engine.run_round(round_number, ChessPosition.initial()).to_dictionary())
	return snapshots


func _climates(position: ChessPosition) -> Array:
	var engine := SimulationEngine.new(null, MixedCongruential.new(5))
	var climates := []
	for round_number in range(1, 26):
		climates.append(engine.run_round(round_number, position).climate)
	return climates


func _test_engine_water() -> void:
	var engine := SimulationEngine.new(null, MixedCongruential.new(3))
	var result := engine.run_round(1, ChessPosition.initial())
	_check(result.water.size() == 2 and is_equal_approx(result.water_percent(PLAYER), result.water_percent(RIVAL)), "cada jugador tiene su propia agua")
	var uneven := SimulationEngine.new(null, MixedCongruential.new(3))
	var after := uneven.run_round(1, ChessPosition.from_fen(PLAYER_WITHOUT_PAWNS))
	_check(after.water_percent(PLAYER) < after.water_percent(RIVAL), "sin frailejones el jugador pierde agua")
	var dry_config := SimulationConfig.new()
	dry_config.initial_water = 0.5
	dry_config.rain_probability = 0.0
	var dry := SimulationEngine.new(dry_config, MixedCongruential.new(2))
	dry.run_round(1, ChessPosition.from_fen(KINGS_ONLY))
	_check(dry.verdict(ChessPosition.from_fen(KINGS_ONLY), 1).reason == Verdict.Reason.BOTH_COLLAPSED, "el motor evalúa la victoria con su agua")


func _test_engine_levels() -> void:
	var engine := SimulationEngine.new(null, MixedCongruential.new(9))
	var position := ChessPosition.initial()
	var started := []
	var spawned := false
	var felled := []
	for round_number in range(1, 26):
		var result := engine.run_round(round_number, position)
		if result.level_started:
			started.append(round_number)
		if round_number <= 20 and result.excavator != null:
			_check(false, "la retroexcavadora no aparece antes del nivel 3")
			return
		spawned = spawned or result.excavator_spawned
		if Board.is_inside(result.felled):
			felled.append(result.felled)
			position.blocked[ChessPosition.to_index(result.felled)] = 1
	_check(started == [11, 21] and engine.level == 3, "sube de nivel en las rondas 11 y 21")
	_check(spawned and Board.is_inside(engine.excavator), "la retroexcavadora aparece en el nivel 3")
	_check(not felled.is_empty() and not felled.has(engine.excavator), "va talando las casillas que deja")


func _test_engine_hunter() -> void:
	var engine := SimulationEngine.new(null, MixedCongruential.new(4))
	var result := engine.run_round(1, ChessPosition.initial())
	_check(result.hunter.step.from == Vector2i(3, 3) and result.hunter.step.to == Vector2i(3, 2), "el cazador sale de d4 hacia el peón más cercano")
	_check(engine.hunter == Vector2i(3, 2), "el motor recuerda dónde está el cazador")
	var next := engine.run_round(2, ChessPosition.initial())
	_check(next.hunter.reward == 1.0 and engine.hunter_reward() == 1.0, "al pisar d2 recibe recompensa")


func _test_engine_nursery() -> void:
	var config := SimulationConfig.new()
	config.nursery_service_rate = 1000.0
	var engine := SimulationEngine.new(config, MixedCongruential.new(2))
	engine.enqueue_capture(RIVAL, RefCounted.new(), 0)
	var result := engine.run_round(1, ChessPosition.initial())
	_check(result.regenerated[PLAYER] == null and result.regenerated[RIVAL] != null, "cada jugador tiene su propio vivero")
	var thirsty_config := SimulationConfig.new()
	thirsty_config.initial_water = 20.0
	thirsty_config.nursery_service_rate = 1000.0
	var thirsty := SimulationEngine.new(thirsty_config, MixedCongruential.new(2))
	thirsty.enqueue_capture(PLAYER, RefCounted.new(), 0)
	_check(thirsty.run_round(1, ChessPosition.initial()).regenerated[PLAYER] == null, "con agua bajo el 30 % el vivero se apaga")


func _test_engine_reset() -> void:
	var engine := SimulationEngine.new(null, MixedCongruential.new(8))
	var first := engine.run_round(1, ChessPosition.initial()).to_dictionary()
	engine.run_round(2, ChessPosition.initial())
	engine.reset()
	_check(engine.hunter == engine.config.hunter_start and engine.water(PLAYER) == 100.0, "reinicio restaura cazador y agua")
	_check(engine.run_round(1, ChessPosition.initial()).to_dictionary() == first, "reinicio reproduce la partida")
