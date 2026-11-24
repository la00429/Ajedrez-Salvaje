# Integrante 5 — Integración y progresión

## Alcance

Construir la partida jugable: escena principal, turnos de dos jugadores, giro
del tablero, rondas y niveles, fase ambiental, vivero, desestabilizadores y
fin de partida. Integración **no duplica reglas**: usa `ChessMatch` para el
ajedrez, `SimulationEngine` para el ambiente y `VictoryRules` (vía
`engine.verdict`) para decidir el ganador.

## Archivos

`scripts/game/` (`GameManager`, `TurnManager`, `LevelManager`,
`VictoryManager`) y `scenes/main/Main.tscn` con `Board.tscn`, una `Camera3D`,
el bioma y `GameHUD.tscn`. El menú abre esta escena cambiando
`GAME_SCENE_PATH` en `scripts/ui/main_menu.gd`.

## Ciclo de una ronda

```gdscript
func start_round() -> void:
	var result := engine.run_round(round_number, match.position)
	apply_environment(result)          # ver tabla
	match.sync()
	hud.show_round(result)             # rol 4
	if not check_end():
		begin_turn(ChessPosition.PLAYER)

func begin_turn(side: int) -> void:
	board.orient_to_side(side)         # el tablero gira 180°
	board.input_enabled = true

func on_move_chosen(move: ChessMove) -> void:
	board.input_enabled = false
	var captured := match.play(move)
	if captured:
		send_to_nursery_or_free(captured)
	if check_end():
		return
	if match.side_to_move() == ChessPosition.PLAYER:
		round_number += 1
		start_round()
	else:
		begin_turn(ChessPosition.RIVAL)
```

| Dato de `RoundResult` | Acción en el tablero |
|---|---|
| `hunter.step` | Si se movió: destruir lo que haya en `to` (peón → `engine.enqueue_capture(dueño, …)`), luego `board.move_piece(from, to)` |
| `excavator_spawned` | Colocar `ChessPiece.create(ChessPiece.Kind.EXCAVATOR, ChessPiece.Team.NEUTRAL)` en `excavator.from` |
| `excavator` | Igual que el cazador |
| `felled` | `board.set_blocked(felled)` |
| `regenerated[side]` | Colocar el peón en `board.first_empty_in_row(1)` (jugador 1) o `(6)` (jugador 2); si la fila está llena, volver a encolarlo |

`check_end()` llama a `engine.verdict(match.position, round_number)` y, si
`is_finished()`, deshabilita el tablero y muestra el resultado. La victoria se
revisa después de cada jugada y de cada fase ambiental.

## Reinicio y pausa

- Reiniciar: `engine.reset()`, `board.clear_pieces()`, `board.clear_blocked()`,
  `match.setup_initial()`, `board.orient_to_side(0, false)`, colocar el cazador
  en `engine.hunter` y `round_number = 1`.
- Pausa: `board.input_enabled = false` y no avanzar rondas.

## Criterios de aceptación

- Una jugada ilegal nunca cambia el estado; una legal sincroniza tablero y
  posición.
- El tablero gira hacia el jugador al que le toca.
- El nivel sube en las rondas 11 y 21 y la retroexcavadora aparece en la 21.
- Capturas y talas de peones llegan al vivero de su dueño con el origen
  correcto.
- `match.sync()` se ejecuta tras cada fase ambiental.
- Cada condición de fin se muestra una sola vez.

## Pruebas

Crear `tests/integration/` para: clic y jugada, alternancia de turnos con giro,
ronda ambiental aplicada al tablero, vivero, subida de nivel, cada condición de
fin, pausa y reinicio. Entregar en una rama `feature/integration-*` hacia
`develop`.
