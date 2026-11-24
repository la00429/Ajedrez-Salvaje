# Modelos de simulación

La capa vive en `scripts/simulation/` y se prueba con
`tests/simulation/test_simulation.gd`. Cada modelo sigue la estructura vista en
clase (nombres en inglés en el código). El detalle de uso para integración
está en [`integrantes/integrante_3_simulacion.md`](integrantes/integrante_3_simulacion.md).

| Tema del curso | Mecánica del juego | Clases |
|---|---|---|
| Generadores congruenciales | Fuente de azar de todos los modelos | `RandomSource`, `MixedCongruential`, `MultiplicativeCongruential`, `SeedMixer` |
| Simulación Monte Carlo | Clima de cada ronda | `MonteCarloMatrix`, `MonteCarloModel`, `MonteCarloEstimate`, `RunningStats`, `Climate` |
| Dinámica de sistemas | Agua de cada jugador | `Stock`, `Flow`, `StockStep`, `WaterSystem`, `Census` |
| Sistemas de espera (M/M/1) | Vivero de cada jugador | `NurseryQueue`, `QueueEntity`, `ExponentialService`, `NurseryServer`, `MM1Theory` |
| Caminata aleatoria 2D | Retroexcavadora (nivel 3) | `RandomWalk`, `WalkStep` |
| Simulación basada en agentes | Cazador furtivo | `HunterEnvironment`, `HunterAgent`, `HunterObservation`, `HunterPerception`, `HunterTransition` |
| Integración | Ronda, niveles y victoria | `SimulationEngine`, `SimulationConfig`, `SideEcosystem`, `RoundResult`, `VictoryRules`, `Verdict` |

## Generadores

- **Congruencia mixta** `x(i+1) = (a·x(i) + c) mod m`, con a = 1664525,
  c = 1013904223, m = 2^32. `satisfies_hull_dobell(a, c, m)` comprueba las tres
  condiciones del teorema (período m).
- **Congruencia multiplicativa (Lehmer)** `x(i+1) = a·x(i) mod m`, con
  a = 16807, m = 2^31 − 1. La semilla debe estar en [1, m − 1] y ser coprima
  con m (`is_valid_seed`).
- Normalización `Ri = xi / m` (`next_r`).
- Cada modelo usa su propio subgenerador (`fork`), derivado de la semilla
  inicial y no del estado consumido: la partida es reproducible y un modelo no
  altera la secuencia de otro. Por la Tabla 2 del documento de preproducción,
  la caminata usa Lehmer y el resto la congruencia mixta.

## Monte Carlo (clima)

1. **Dominio:** eventos estable, lluvia, helada y catástrofe.
2. **Entradas:** un Ri por ronda.
3. **Cálculo:** `MonteCarloMatrix` asigna a cada evento un rango de r según su
   probabilidad acumulada. Clima normal: [0, 0.70) estable, [0.70, 0.85)
   lluvia, [0.85, 0.98) helada, [0.98, 1) catástrofe (documento de
   preproducción). Clima severo (nivel 2 en adelante): 0.60 / 0.10 / 0.25 / 0.05.
4. **Agregación:** `MonteCarloModel` repite un ensayo N veces y entrega media,
   desviación, error estándar (cota 1/√N) e intervalo del 95 %.

## Dinámica de sistemas (agua)

- **Variable de estado:** `Stock` con el nivel de agua A(t) en [0, 100] %.
- **Variables de flujo** (`Flow`, con polaridad):
  - (+) condensación = 0.2 × frailejones vivos;
  - (+) lluvia = 4.0 si llueve;
  - (−) evaporación = 1.0, triplicada en helada;
  - (−) consumo = 0.6/7 × animales vivos;
  - (−) catástrofe = 8.0 si ocurre (supuesto).
- **Integración de Euler:** `A(t+dt) = A(t) + dt · Σ polaridad · tasa`, con
  dt = 1 ronda. `StockStep.adjustment` registra lo que recorta el límite.
- **Realimentación:** agua > 30 % enciende el vivero → rebrotan frailejones →
  más condensación → más agua.

La prueba "Partida de ejemplo del documento de preproducción" reproduce los
valores A(1..4) = 100, 98, 98, 100 %.

## Sistema de espera (vivero M/M/1)

- **Entidades** (`QueueEntity`): instante de llegada, inicio de servicio,
  tiempo de servicio, instante de salida, tiempo de espera y tiempo en el
  sistema.
- **Disciplina** FIFO con capacidad finita (16, supuesto).
- **Servicio exponencial** por transformación inversa: `t = −ln(1 − U)/μ`, con
  μ = 0.5 por ronda (1/μ = 2 rondas, documento de preproducción).
- **Servidor** (`NurseryServer`): uno solo, con estado encendido o apagado
  (apagado si el agua del jugador está en 30 % o menos). Mide λ observado,
  utilización y tiempo medio en el sistema.
- **Teoría** (`MM1Theory`): ρ = λ/μ, L, Lq, W y Wq; el estado estacionario
  existe solo si ρ < 1.

Las llegadas son eventos del juego (capturas y talas), no se sortean.

## Caminata aleatoria 2D (retroexcavadora)

- Posición X(n) y ecuación de estado `x(n+1) = x(n) + s(n)`.
- Incremento s(n) con probabilidad 1/4 por dirección: [0, .25) Norte,
  [.25, .5) Sur, [.5, .75) Este, [.75, 1) Oeste.
- Borde: `REDRAW` (por defecto) sortea entre las direcciones válidas; `STAY` se
  queda quieto y conserva p = 1/4 exacto.
- `displacement()` y `squared_distance()` permiten medir la dispersión. Con
  pasos ortogonales unitarios E[X² + Y²] = n (los apuntes indican 2n; la prueba
  mide n).

## Agente cazador

Sigue la estructura de agentes vista en clase (entorno, observación, política,
acción, recompensa) y el ciclo percepción-acción:

| Componente | Implementación |
|---|---|
| Entorno | `HunterEnvironment`: `reset` y `step(action)` devuelven observación, recompensa y fin |
| Espacio de observación | `HunterObservation`: posición del cazador, piezas y acciones legales |
| Percepción | `HunterAgent.perceive`: piezas más cercanas por distancia de Manhattan |
| Estado interno | `HunterAgent.target`: la presa elegida, que conserva mientras siga siendo la más cercana |
| Política | `HunterAgent.policy`: una acción que reduce la distancia a la presa |
| Espacio de acción | Norte, Sur, Este, Oeste o quedarse |
| Recompensa | 1 por pieza destruida; `total_reward` acumula la partida |

Es un agente heurístico: un solo agente con regla local, sin agentes que
interactúen entre sí.

## Valores

Los tomados del documento de preproducción están marcados; el resto son
supuestos y se cambian en `SimulationConfig`.

| Parámetro | Valor | Origen |
|---|---|---|
| A(0), tope | 100 % | documento |
| Clima normal | 0.70 / 0.15 / 0.13 / 0.02 | documento |
| Condensación, evaporación, lluvia | 0.2 por planta, 1.0 (x3 en helada), 4.0 | documento |
| Consumo | 0.6/7 por animal | documento |
| μ del vivero, umbral | 0.5 por ronda, 30 % | documento |
| Cazador inicial | d4 | documento |
| Clima severo | 0.60 / 0.10 / 0.25 / 0.05 | supuesto |
| Catástrofe | 8.0 | supuesto |
| Capacidad del vivero | 16 | supuesto |
| Rondas por nivel, ronda final | 10, 30 | supuesto |
| Borde de la retroexcavadora | REDRAW | supuesto |
