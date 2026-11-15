# Integración de módulos

## Contratos

| Productor | Contrato | Consumidor |
|---|---|---|
| `Board` | `cell_clicked`, `cell_hovered`, `piece_moved` y consultas de ocupación | `ChessMatch`, `TurnManager`, HUD |
| `ChessMatch` | `legal_moves_from`, `find_move`, `play`, `sync`, `status`, `move_played` | integración y simulación |
| Simulación | resultado tipado/serializable y eventos de agente/vivero | integración y HUD |
| Integración | estado de turno, nivel y fin | UI y módulos |
| `GameHUD` | métodos `set_*` y señales de intención | integración |

## Firmas recomendadas

```gdscript
func on_cell_clicked(coord: Vector2i) -> void
func execute_player_move(from: Vector2i, to: Vector2i, promotion: int) -> bool
func run_environment_phase(turn: int) -> SimulationResult
func enqueue_capture(piece: ChessPiece, source: StringName) -> void
func on_simulation_updated(result: SimulationResult) -> void
```

`SimulationResult`, `LevelConfig` y `TurnState` aún no existen en el
repositorio; son tipos propuestos y deben definirse antes de usarse.

## Responsabilidades y límites

Integrante 1 no decide legalidad. Integrante 2 no consulta simulaciones.
Integrante 3 no mueve nodos del tablero directamente: solicita operaciones a
integración. Integrante 4 presenta datos. Integrante 5 conecta señales,
controla fases y decide transiciones.

## Vivero y eventos

El contrato debe incluir `source` (`capture` o `harvest`) y la pieza/elemento
recibido. Un peón devuelto por `ChessMatch.play` puede enviarse al vivero,
pero una cosecha voluntaria debe entrar por un método/evento separado. No se
deben mezclar ambos contadores.

## Orden de integración

Primero probar `Board` + `ChessMatch`, luego conectar HUD, después inyectar un
resultado simulado fijo y finalmente sustituirlo por el motor ambiental. Cada
fase debe poder deshabilitarse para aislar fallos.
