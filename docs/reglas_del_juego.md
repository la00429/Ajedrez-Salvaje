# Reglas del juego

## Ajedrez tradicional

La partida usa el tablero completo de 64 casillas y seis tipos de pieza:

| Pieza | Movimiento |
|---|---|
| Peón | Avanza una casilla, dos desde su salida; captura en diagonal |
| Caballo | Salta en forma de L |
| Alfil | Desplazamiento diagonal sin saltar |
| Torre | Desplazamiento ortogonal sin saltar |
| Dama | Combina alfil y torre |
| Rey | Una casilla en cualquier dirección |

Las piezas no pueden atravesar ocupantes. Una captura elimina la pieza rival;
un movimiento es legal solo si deja a salvo el propio rey. Se contemplan
jaque, jaque mate y ahogado.

## Reglas especiales

- **Enroque:** corto o largo, si no se movieron rey/torre, el camino está
  libre, el rey no está en jaque y no atraviesa casillas atacadas.
- **Captura al paso:** solo inmediatamente después del avance doble rival.
- **Promoción:** un peón que alcanza la última fila puede transformarse en
  dama, torre, alfil o caballo.
- **Tablas:** el ahogado está implementado. Las tablas por 50 movimientos,
  triple repetición y material insuficiente están pendientes en el código.

## Representación y validación

`ChessPosition.squares` usa índices 0–63 y códigos de pieza/bando; soporta FEN,
turno, `castling`, `en_passant`, `halfmove_clock` y `fullmove_number`.
`MovementValidator.legal_moves` genera candidatas, aplica cada una sobre una
copia y descarta las que dejan al rey atacado. `status` devuelve `PLAYING`,
`CHECK`, `CHECKMATE`, `STALEMATE` o `KING_LOST`.

## Mecánicas ambientales separadas

El cazador neutral, las casillas bloqueadas, vivero y simulaciones no redefinen
las reglas FIDE. Actualmente `ChessPosition` permite configurar si el cazador
es capturable y si las casillas bloqueadas son transitables. La decisión sobre
qué hacer cuando un agente intenta salir del tablero y sobre la captura de un
rey por el cazador debe aprobarse en integración.