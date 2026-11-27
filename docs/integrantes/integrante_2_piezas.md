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
- **Las reglas** (`ChessPosition` + `MovementValidator`): no tocan nodos. Así se pueden probar solas y la simulación puede leer la posición sin mover nada en pantalla.
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
match.winner()   # 0 jugador 1, 1 jugador 2, -1 nadie (en curso o tablas)
```

Para consultar la posición sin mover nada en pantalla:

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

- **Simulación (integrante 3):** usa `count` y `material` (hecho). El consumo de
  agua quedó en 0.6/7 por animal para mantener el −0.6 % del documento con 7
  animales por bando.
- **Integración (integrante 5):** enviar los peones capturados al vivero de su
  dueño con `engine.enqueue_capture`, llamar a `match.sync()` después de la fase
  ambiental y girar el tablero en cada turno.
- **Documento:** actualizar la sección 4.2, que todavía habla del set reducido.

## Orden, aceptación y entrega

1. Mantener `ChessPosition` independiente de nodos.
2. Completar/validar `MovementValidator` con casos FIDE.
3. Integrar `ChessMatch` con `Board`.
4. Conectar selección, promoción y estado final al gestor de turnos.

La aceptación exige que una jugada ilegal no mute posición ni tablero, que
perft conserve sus valores conocidos, que `sync()` soporte cambios externos y
que el módulo no consulte simulaciones para legalidad. Entregar en
`feature/chess-rules-*` con pruebas headless y la lista de FEN/casos cubiertos.

## Cambios para el juego de dos jugadores

- Los bandos son **jugador 1** (`Team.PLAYER`, blancas) y **jugador 2**
  (`Team.RIVAL`, negras); `display_name()` lo refleja.
- Nuevo ocupante neutral `Kind.EXCAVATOR` (retroexcavadora, nivel 3) con su
  modelo 3D. `ChessPiece.is_neutral()` e `is_neutral_kind()` cubren cazador y
  retroexcavadora; ambos cuentan como `NEUTRAL` en `ChessPosition.from_board`.
- `ChessPosition.count(kind, side)` cuenta piezas de un tipo; la simulación lo
  usa para saber cuántos frailejones y animales tiene cada jugador.
- `ChessPosition.material(side)` suma el valor clásico de las piezas; desempata
  la ronda final.
- Ya no hay rival automático: el rival provisional de la demo queda solo como
  herramienta de prueba.
