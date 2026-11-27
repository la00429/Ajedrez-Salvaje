# Especificación técnica

## Plataforma

`project.godot` declara Godot 4.7, renderer GL Compatibility, ventana con
estiramiento `canvas_items` y escena principal `res://scenes/ui/MainMenu.tscn`.
El lenguaje es GDScript. La representación del tablero y piezas es 3D; el HUD
es 2D sobre un `CanvasLayer`/`Control`.

## Organización

| Ruta | Convención |
|---|---|
| `scripts/board/` | clases `Board`, `Cell`, temas y efectos |
| `scripts/pieces/` | estado, movimientos, modelos y puente 3D |
| `scripts/ui/` | menú, HUD, estilos e iconos |
| `scenes/` | escenas reutilizables con nombres PascalCase |
| `tests/` | pruebas y demos, separadas por módulo |
| `resources/` | configuraciones `.tres` por bioma o pieza |

Las clases usan `class_name` cuando son contratos compartidos. Las funciones
públicas tienen tipos explícitos y las constantes usan mayúsculas. Las
coordenadas de tablero son `Vector2i(columna, fila)`, con a1 = `(0, 0)`.

## Escenas y contratos

`Board.tscn` organiza `Frame`, `Cells`, `Pieces` y `Effects`. `Cell.tscn`
representa una casilla. `ChessPiece.tscn` es el nodo visual de una pieza.
`GameHUD.tscn` y `MainMenu.tscn` componen la UI. La escena principal aún no
contiene un `GameManager` documentado en el árbol actual: es trabajo de
integración pendiente.

Señales principales:

```gdscript
signal cell_clicked(coord: Vector2i)
signal piece_moved(piece: Node3D, from: Vector2i, to: Vector2i)
signal move_played(move: ChessMove)
signal pause_changed(paused: bool)
```

## Estado

`ChessPosition` contiene casillas, bando al turno, derechos de enroque,
captura al paso y contadores FEN. `MovementValidator` devuelve nuevas
posiciones mediante `apply`, sin mutar la original. `ChessMatch` mantiene la
posición y sincroniza los nodos del tablero después de cambios externos.

## Calidad

Todo cambio debe conservar tipado, separar cálculo de presentación, incluir
pruebas del comportamiento nuevo y pasar las pruebas headless relevantes. No
se deben ocultar errores con `catch` amplio ni asumir que una señal equivale a
estado persistente.