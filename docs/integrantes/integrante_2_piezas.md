# Integrante 2 — Piezas y reglas de ajedrez

**Decisión:** se juega con el **set completo FIDE**: las 6 piezas, enroque, captura al paso y coronación. Esto reemplaza al "set reducido" de la sección 4.2 del documento y coincide con la partida de ejemplo de la sección 5.

Cada pieza es una especie colombiana:

| Pieza | Especie | Por bando |
|---|---|---|
| Peón | Frailejón | 8 |
| Caballo | Venado de cola blanca | 2 |
| Alfil | Cóndor andino | 2 |
| Torre | Oso de anteojos | 2 |
| Dama | Danta de montaña | 1 |
| Rey | Frailejón Gran Abuelo | 1 |
| — | Cazador furtivo (neutral, no es pieza de ajedrez) | — |

## Archivos

| Archivo | Contenido |
|---|---|
| `scripts/pieces/chess_piece.gd` | `ChessPiece` (`Node3D`): tipo, bando y modelo 3D de una pieza |
| `scripts/pieces/piece_models.gd` | Modelos 3D de las 7 figuras, hechos por código |
| `scripts/pieces/mesh_kit.gd` | Formas básicas para los modelos (también las usa la demo) |
| `scripts/pieces/chess_position.gd` | `ChessPosition`: estado de la partida (casillas, turno, enroques, captura al paso), FEN |
| `scripts/pieces/chess_move.gd` | `ChessMove`: una jugada, con notación en español ("Cf3", "O-O", "e8=D") |
| `scripts/pieces/movement_validator.gd` | `MovementValidator`: jugadas legales, jaque, mate, ahogado, perft |
| `scripts/pieces/chess_match.gd` | `ChessMatch`: une las reglas con el tablero 3D |
| `scenes/pieces/ChessPiece.tscn` | Escena de una pieza |
| `tests/pieces/test_rules.gd` | Pruebas (77 comprobaciones, incluido perft) |

Las notas del repo preveían un archivo por pieza (`pawn.gd`, `knight.gd`...). Se juntaron en `movement_validator.gd`, porque el movimiento de cada pieza son pocas líneas y así todas las reglas quedan en un solo lugar.

## Cómo está separado

- **Lo visual** (`ChessPiece`): un nodo 3D con `kind` y `side`. Si `kind` cambia (por ejemplo, al coronar), se reconstruye el modelo.
- **Las reglas** (`ChessPosition` + `MovementValidator`): no tocan nodos. Así se pueden probar solas y la IA rival puede simular jugadas sin mover nada en pantalla.
- **El puente** (`ChessMatch`): ejecuta en el tablero las jugadas que las reglas aprueban y mantiene la posición sincronizada.

## Uso (para integración y simulación)

```gdscript
var match := ChessMatch.new(board)
match.setup_initial()                           # 32 piezas en posición inicial FIDE

# Turno del jugador: resaltar destinos legales de la pieza elegida
for move in match.legal_moves_from(coord):
    board.set_highlight(move.to_coord(), Cell.Highlight.CAPTURE if move.is_capture() else Cell.Highlight.MOVE)

# Ejecutar la jugada elegida (coronación a dama por defecto)
var move := match.find_move(from, to)
var captured := match.play(move)                # devuelve la pieza capturada SIN liberarla
if captured:
    vivero.enqueue(captured)                    # o captured.queue_free()

# Después de que el cazador, el vivero o una catástrofe cambien el tablero:
match.sync()

match.status()   # PLAYING, CHECK, CHECKMATE, STALEMATE o KING_LOST
match.winner()   # 0 jugador, 1 rival, -1 nadie (en curso o tablas)
```

Para la IA rival (agentes ABM) conviene trabajar con la posición, sin mover nada en pantalla:

```gdscript
var moves := MovementValidator.legal_moves(match.position)   # jugadas del bando al que le toca
var after := MovementValidator.apply(match.position, moves[0]) # posición resultante, para evaluar
MovementValidator.is_square_attacked(after, index, ChessPosition.PLAYER)
```

## Reglas implementadas

- Movimiento de las 6 piezas. Alfil, torre y dama necesitan el camino libre; el caballo salta.
- Capturas, jaque (no se permiten jugadas que dejen al propio rey en jaque), jaque mate y ahogado.
- **Enroque** corto y largo: no se puede estando en jaque, pasando por casillas atacadas, ni después de mover el rey o la torre.
- **Captura al paso**, solo en la jugada inmediata.
- **Coronación** a dama, torre, alfil o caballo. `ChessMatch.find_move` elige dama si no se indica otra cosa.
- **No implementado:** tablas por 50 jugadas, por triple repetición y por material insuficiente.

## Reglas propias del juego

Son decisiones del equipo y se pueden cambiar con dos opciones de `ChessPosition`:

| Situación | Comportamiento actual | Opción |
|---|---|---|
| Cazador | Bloquea el paso, no da jaque y no se puede capturar | `hunter_capturable = true` permite capturarlo |
| Casilla bloqueada | No se puede pisar ni atravesar; el caballo sí salta por encima | `blocked_passable = true` las ignora |
| Rey destruido por el cazador | La partida termina (`KING_LOST`) y gana el otro bando | — |

## Verificación

Se validó el generador con **perft**: contar todas las posiciones posibles a cierta profundidad y compararlas con valores publicados.

| Posición | Profundidad | Posiciones |
|---|---|---|
| Inicial | 3 | 8.902 |
| Kiwipete | 2 | 2.039 |
| Posición 3 | 3 | 2.812 |
| Posición 4 | 2 | 264 |
| Posición 5 | 2 | 1.486 |

Todas coinciden. Esto cubre enroques, capturas al paso, coronaciones y clavadas.

```bash
godot --headless --path . --script res://tests/pieces/test_rules.gd
```

Para probar una posición concreta en la demo (un enroque, un final, un mate), se le pasa en notación FEN:

```bash
godot --path . res://tests/board/board_demo.tscn -- --fen="r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1"
```

## Pendientes para otros módulos

- **Simulación (integrante 3):**
  - **Agua.** El consumo de −0.6% del documento cuadraba con 2 animales por bando (los venados). Con el set completo hay 7 animales por bando: venados, cóndores, osos y danta. Hay que recalibrar `k_c` (por ejemplo, ≈0.086% por animal para mantener −0.6%).
  - **Vivero.** Recibe los peones que devuelve `ChessMatch.play()`.
  - **IA rival.** Debe elegir entre `MovementValidator.legal_moves()`. La demo trae un rival provisional muy simple.
- **Integración (integrante 5):** orden de fases del turno, y llamar a `match.sync()` después de las fases del cazador y del vivero.
- **Documento:** actualizar la sección 4.2, que todavía habla del set reducido.
