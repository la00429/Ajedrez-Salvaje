# Integrante 3 — Motor de simulación

## Alcance

Los modelos del curso que mueven el ecosistema y los desestabilizadores, con
la estructura vista en clase: generadores congruenciales, Monte Carlo,
dinámica de sistemas, sistema de espera M/M/1, caminata aleatoria 2D y un
agente. También las condiciones de victoria, porque combinan ajedrez y agua.

El motor **no mueve nodos**: recibe la posición de ajedrez y devuelve qué
cambió. Integración aplica esos cambios en el tablero. El detalle de cada
modelo está en [`../modelos_simulacion.md`](../modelos_simulacion.md).

## Archivos

| Archivo | Clase | Papel |
|---|---|---|
| `random_source.gd` | `RandomSource` | Interfaz de azar inyectable (`next_r`, `fork`) |
| `mixed_congruential.gd` | `MixedCongruential` | Congruencia mixta y Hull-Dobell |
| `multiplicative_congruential.gd` | `MultiplicativeCongruential` | Lehmer |
| `seed_mixer.gd` | `SeedMixer` | Semillas de los subgeneradores |
| `monte_carlo_matrix.gd` | `MonteCarloMatrix` | Rangos de r por evento |
| `monte_carlo.gd`, `monte_carlo_estimate.gd`, `running_stats.gd` | `MonteCarloModel`, `MonteCarloEstimate`, `RunningStats` | Réplicas y agregación (media, desviación, IC 95 %) |
| `climate.gd` | `Climate` | Eventos climáticos y etiquetas para el HUD |
| `stock.gd`, `flow.gd`, `stock_step.gd` | `Stock`, `Flow`, `StockStep` | Variable de estado, variables de flujo y paso de Euler |
| `water_system.gd`, `census.gd` | `WaterSystem`, `Census` | Flujos del agua según plantas y animales vivos |
| `queue_entity.gd`, `nursery_queue.gd` | `QueueEntity`, `NurseryQueue` | Entidades con sus tiempos y cola FIFO |
| `exponential_service.gd`, `nursery_server.gd`, `mm1_theory.gd` | `ExponentialService`, `NurseryServer`, `MM1Theory` | Servicio exponencial, servidor encendido/apagado y fórmulas M/M/1 |
| `random_walk.gd`, `walk_step.gd` | `RandomWalk`, `WalkStep` | Caminata de la retroexcavadora |
| `hunter_environment.gd`, `hunter_agent.gd`, `hunter_observation.gd`, `hunter_perception.gd`, `hunter_transition.gd` | `HunterEnvironment`, `HunterAgent`, … | Agente cazador |
| `side_ecosystem.gd` | `SideEcosystem` | Agua y vivero de un jugador |
| `round_result.gd` | `RoundResult` | Todo lo que cambió en una ronda |
| `verdict.gd`, `victory_rules.gd` | `Verdict`, `VictoryRules` | Condiciones de victoria |
| `simulation_config.gd` | `SimulationConfig` | Todos los parámetros (`Resource`, se puede guardar como `.tres`) |
| `simulation_engine.gd` | `SimulationEngine` | Ejecuta la fase ambiental de cada ronda |

## Uso desde integración

```gdscript
var engine := SimulationEngine.new(config)            # config opcional
board.place_piece(ChessPiece.create(ChessPiece.Kind.HUNTER, ChessPiece.Team.NEUTRAL), engine.hunter)

# Al inicio de cada ronda (antes de que jueguen los dos)
var result := engine.run_round(round_number, match.position)

# Una captura de ajedrez de un peón entra al vivero de su dueño
var captured := match.play(move)
if captured and captured.kind == ChessPiece.Kind.PAWN:
	engine.enqueue_capture(captured.side, captured, round_number)

# Después de cada jugada y de cada ronda
var verdict := engine.verdict(match.position, round_number)
```

### Qué trae `RoundResult`

| Campo | Qué hacer con él |
|---|---|
| `level`, `level_started` | Mostrar el nivel; si empezó, hacer la intro del nivel |
| `climate`, `climate_label()` | HUD |
| `water[side]` (`StockStep`), `water_percent(side)` | HUD; detalle de flujos con `rate_of(...)` |
| `regenerated[side]` (`QueueEntity` o `null`) | Colocar el peón (`payload`) en `board.first_empty_in_row(1)` o `(6)` |
| `queue_lengths[side]` | HUD (plantas en el vivero) |
| `hunter.step` (`WalkStep`) | Mover el cazador; si `to` tenía una pieza, destruirla (y si es peón, `enqueue_capture`) |
| `excavator_spawned`, `excavator` (`WalkStep`) | Colocar la retroexcavadora en `excavator.from` si apareció; moverla y destruir lo que pise |
| `felled` | `board.set_blocked(felled)` |

Después de aplicar los cambios, `match.sync()`.

### Estado del motor

`engine.level`, `engine.hunter`, `engine.excavator`, `engine.water(side)`,
`engine.nursery(side)` (con `utilization()`, `arrival_rate()`,
`average_system_time()`), `engine.hunter_reward()` y `engine.reset()`.

## Garantías

- Misma semilla, misma partida; `reset()` la repite.
- Cada modelo tiene su propio subgenerador: el clima no cambia aunque cambien
  las jugadas.
- El cazador y la retroexcavadora no entran a casillas bloqueadas ni se pisan
  entre sí.
- No modifica reglas FIDE ni nodos.

## Pruebas

```bash
godot --headless --path . --script res://tests/simulation/test_simulation.gd
```

Cubren cada modelo por separado, la partida de ejemplo del documento de
preproducción, los niveles, las condiciones de victoria y el motor completo.

## Pendiente

Los valores supuestos listados en [`../decisiones_tecnicas.md`](../decisiones_tecnicas.md).
