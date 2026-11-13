# Integrante 1 — Tablero y casillas

El tablero es **3D**. Administra **posiciones**: la matriz 8x8, qué ocupa cada casilla, colocar, mover y retirar ocupantes, límites, vecindades, bloqueos y resaltados. También detecta los clics con un rayo desde la cámara.

**No valida reglas de ajedrez.** Eso le toca al módulo de piezas (`movement_validator.gd`). El tablero solo comprueba que la operación sea posible físicamente: que esté dentro del tablero, que el origen esté ocupado y que el destino esté libre.

## Archivos

| Archivo | Contenido |
|---|---|
| `scripts/board/board.gd` | Clase `Board` (`Node3D`): matriz, ocupación, geometría, clics, marco y animaciones |
| `scripts/board/cell.gd` | Clase `Cell` (`Node3D`): bloque de la casilla y capa de resaltado |
| `scripts/board/board_theme.gd` | Clase `BoardTheme`: colores del tablero y temas por bioma |
| `scripts/board/board_effect.gd` | Partículas y onda al retirar una pieza o bloquear una casilla |
| `scenes/board/Board.tscn` | Escena del tablero, con las capas `Frame`, `Cells`, `Pieces` y `Effects` |
| `scenes/board/Cell.tscn` | Escena de una casilla |
| `scenes/board/tile.gdshader` | Textura orgánica de las casillas (ruido fractal) |
| `scenes/board/cell_overlay.gdshader` | Resaltados: selección, movimientos, capturas, jaque, cursor y tierra quemada |
| `tests/board/test_board.gd` | Pruebas automáticas |
| `tests/board/board_demo.tscn` | Demo 3D con fichas de relleno, entorno por bioma y panel |
| `tests/board/demo_environment.gd`, `demo_terrain.gd`, `demo_creatures.gd`, `shaders/` | Ambientación de la demo: terreno, agua, vegetación con viento, niebla, partículas y fauna (reutilizable por el módulo de biomas) |

## Convenciones

Las coordenadas son `Vector2i(columna, fila)`: columna 0–7 = **a–h** y fila 0–7 = **1–8**.

- `Vector2i(4, 3)` es **e4**.
- a1 es oscura, como en el ajedrez real.
- **Norte** es hacia la fila 8: `Board.NORTH = Vector2i(0, 1)`.
- `Board.INVALID = Vector2i(-1, -1)` significa "fuera del tablero" o "no encontrado".

En el espacio local del tablero (unidades de mundo, `cell_size = 1` por defecto):

- El centro del tablero está en el origen.
- La cara superior de las casillas está en `y = 0`.
- La columna **a** queda hacia **−X** y la fila **1** (jugador) hacia **+Z**. Por eso la cámara del jugador va en +Z mirando hacia −Z.
- `coord_to_position(coord)` devuelve el centro de la cara superior de la casilla. Ahí se apoya la base de la pieza.

```gdscript
Board.algebraic_to_coord("e4")          # Vector2i(4, 3)
Board.coord_to_algebraic(Vector2i(4,3)) # "e4"
board.coord_to_position(Vector2i(4, 3)) # Vector3(0.5, 0, 0.5)
```

## API

### Geometría (estáticas, no necesitan una instancia)

| Función | Devuelve |
|---|---|
| `is_inside(coord)` | `true` si está en el tablero |
| `is_light_square(coord)` | `true` si la casilla es clara |
| `coord_to_algebraic(coord)` / `algebraic_to_coord(text)` | Conversión de notación |
| `manhattan_distance(a, b)` | \|dx\| + \|dy\| (agentes frente al cazador) |
| `chebyshev_distance(a, b)` | max(\|dx\|, \|dy\|) |
| `get_moore_neighborhood(center, radius)` | Vecindad de Moore sin el centro (radio 2 para ABM) |
| `get_orthogonal_neighbors(center)` | Vecinos N, S, E, O dentro del tablero |
| `ORTHOGONAL_DIRECTIONS` | `[NORTH, SOUTH, EAST, WEST]`, en el orden de la partición de la caminata 2D |

### Posiciones 3D

| Función | Devuelve |
|---|---|
| `coord_to_position(coord) -> Vector3` | Centro de la cara superior de la casilla (local) |
| `position_to_coord(local: Vector3) -> Vector2i` | Casilla bajo un punto local (ignora la altura) |
| `ray_to_coord(origin, direction) -> Vector2i` | Casilla que toca un rayo global. Si atraviesa el cuerpo de una pieza, devuelve la casilla de esa pieza |
| `get_board_size()` / `get_frame_width()` | Lado del área de casillas y ancho del marco |
| `get_bounds() -> AABB` | Caja que ocupa todo el tablero (marco y base incluidos), útil para encuadrar la cámara |

### Ocupación

| Función | Qué hace |
|---|---|
| `get_piece_at(coord)` | Ocupante de la casilla, o `null` |
| `is_empty(coord)` / `is_occupied(coord)` | Consulta de ocupación |
| `find_piece(piece)` | Coordenada de un ocupante, o `INVALID` |
| `place_piece(piece: Node3D, coord) -> bool` | Coloca un nodo en una casilla vacía |
| `move_piece(from, to) -> bool` | Mueve a una casilla **vacía**, con un salto animado. No captura de forma implícita |
| `remove_piece(coord, effect = true) -> Node3D` | Retira el ocupante **sin liberarlo** y lo devuelve. Muestra polvo salvo que `effect` sea `false` |
| `destroy_piece(coord, effect = true) -> bool` | Retira el ocupante y lo libera de memoria |
| `clear_pieces()` | Libera todos los ocupantes |
| `get_all_pieces()` / `get_occupied_coords()` / `get_empty_coords()` | Listados |
| `get_empty_coords_in_row(row)` / `first_empty_in_row(row)` | Para el vivero (replantar en la fila de origen) |

Cualquier `Node3D` puede ocupar una casilla: piezas, el cazador o especies invasoras. Solo hay **un ocupante por casilla**. El origen del nodo de la pieza debe estar en la base del modelo.

**Altura de clic.** Por defecto, el clic considera que una pieza mide 1.1 casillas. Si una pieza es más alta o más baja, se ajusta así:

```gdscript
piece.set_meta(&"board_pick_height", 0.8)   # en casillas
```

### Estado visual

| Función | Qué hace |
|---|---|
| `set_highlight(coord, kind)` / `highlight_cells(coords, kind)` | Resalta casillas: `Cell.Highlight.SELECTED`, `MOVE`, `CAPTURE`, `CHECK`, `LAST_MOVE` |
| `get_highlight(coord)` / `clear_highlights()` | Consulta o limpia los resaltados |
| `set_blocked(coord, bool)` / `is_blocked(coord)` / `clear_blocked()` | Casilla intransitable (catástrofe, tala): se ve como tierra quemada con grietas encendidas |
| `board_theme = BoardTheme.create(&"amazonia")` | Cambia todo el aspecto: casillas, marco, resaltados y efectos |
| `apply_palette(light, dark)` | Cambia solo los colores de las casillas |
| `get_cell(coord).custom_material = ...` | Material propio para una casilla (por ejemplo, una textura del bioma) |
| `play_intro()` | Repite la animación de entrada (por ejemplo, al empezar un nivel) |
| `spawn_effect(coord, color)` | Partículas y onda en una casilla |

Propiedades exportadas:

- `board_theme`, `cell_size` y `show_coordinates`.
- `animations_enabled` y `play_intro_on_ready`. Hay que desactivarlas en pruebas.
- `move_duration`.
- `input_enabled`. Con `input_enabled = false` el tablero ignora los clics, por ejemplo durante el turno rival.

### Señales

| Señal | Cuándo |
|---|---|
| `cell_clicked(coord)` | Clic izquierdo en una casilla o en la pieza que la ocupa |
| `cell_right_clicked(coord)` | Clic derecho (por ejemplo, para cancelar la selección) |
| `cell_hovered(coord)` | El cursor cambia de casilla (`INVALID` al salir) |
| `piece_placed(piece, coord)` | Se colocó un ocupante |
| `piece_moved(piece, from, to)` | Se movió un ocupante |
| `piece_removed(piece, coord)` | Se retiró un ocupante |
| `cell_blocked_changed(coord, blocked)` | Cambió el bloqueo de una casilla |

## Aspecto y animaciones

- **Intro:** al entrar a la escena, las casillas emergen en ola desde a1 y después caen las piezas fila por fila con un rebote.
- **Movimiento:** `move_piece` hace que la pieza salte en arco y se aplaste un poco al aterrizar.
- **Colocar y retirar:** `place_piece` hace brotar la pieza. Retirarla o talarla lanza partículas y una onda.
- **Resaltados:** la selección y el jaque laten, los movimientos se marcan con un punto y las capturas con esquinas y un anillo.
- **El tablero conserva la escala original de cada pieza.** El módulo de piezas puede escalar sus modelos como quiera.
- **Temas:** hay cuatro listos: `&"paramo"` (por defecto), `&"amazonia"`, `&"santuario"` y `&"clasico"`.

## Cómo lo usa cada módulo

**Piezas (Integrante 2): validar y ejecutar una captura.** El validador decide si la jugada es legal. El tablero solo la ejecuta, en dos pasos:

```gdscript
var captured := board.remove_piece(to)   # null si no había nada
board.move_piece(from, to)
if captured:
    captured.queue_free()                # o enviarlo al vivero si es un peón
```

Para calcular movimientos, el validador consulta `Board.is_inside()`, `board.get_piece_at()` y, si el equipo lo decide, `board.is_blocked()`. Después los muestra con `board.highlight_cells(moves, Cell.Highlight.MOVE)`. Las piezas son `ChessPiece` (`Node3D` con el origen en la base). Las reglas y la conexión con el tablero (`ChessMatch`) están documentadas en `docs/integrantes/integrante_2_piezas.md`.

**Simulación (Integrante 3): cazador y vivero.**

```gdscript
# Caminata 2D: r en [0, 1) del generador de Lehmer
var step := Board.ORTHOGONAL_DIRECTIONS[int(r * 4.0)]
var to := hunter_coord + step
if Board.is_inside(to):
    board.destroy_piece(to)               # tala o aplastamiento, si había algo
    board.move_piece(hunter_coord, to)

# Vivero: el peón regenerado vuelve a la primera casilla libre de su fila
var spot := board.first_empty_in_row(1)  # fila 2 del jugador
if spot != Board.INVALID:
    board.place_piece(pawn, spot)
```

Los agentes ABM usan `Board.get_moore_neighborhood(coord, 2)` y `Board.manhattan_distance(coord, hunter_coord)`.

**Biomas y HUD (Integrante 4).**

- Al cargar un nivel, se cambia el tema con `board.board_theme = BoardTheme.create(&"amazonia")` o con un `.tres` propio.
- Un material especial para una casilla se pone con `board.get_cell(coord).custom_material`.
- El entorno de cada bioma (cielo, luz, vegetación) va en las escenas de biomas. `tests/board/demo_environment.gd` es un ejemplo.
- El HUD sigue siendo 2D, en un `CanvasLayer` encima de la vista 3D. Para mostrar la casilla bajo el cursor hay que conectar `cell_hovered`.

**Integración (Integrante 5).**

- `Main.tscn` instancia `Board.tscn` y necesita una `Camera3D` activa: el tablero la usa para los clics.
- Conecta `cell_clicked` al flujo de turnos y usa `input_enabled` para bloquear la entrada fuera del turno del jugador.
- Al reiniciar un nivel llama a `clear_pieces()`, `clear_blocked()` y, si quiere, a `play_intro()`.
- `get_bounds()` sirve para encuadrar la cámara.

### Notas de iluminación (renderer de compatibilidad)

El proyecto usa el renderer **GL Compatibility**, y ahí la luz se satura con facilidad. Lo que mejor funcionó en la demo:

- Luz ambiental de **color fijo** (`AMBIENT_SOURCE_COLOR`, energía de 0.4 aproximadamente) en lugar de la del cielo, que lava los colores.
- Sol de energía 0.75–0.85 con sombras.
- Niebla por **profundidad**, que empiece lejos del tablero, en lugar de niebla exponencial.

## Pruebas y demo

```bash
# Pruebas automáticas
godot --headless --path . --script res://tests/board/test_board.gd
```

Al final se imprime `N comprobaciones, 0 fallidas`. Hay que revisar esa línea y no solo el código de salida, porque si un script no compila Godot igual termina con código 0. Si aparece `Could not find type "BoardTheme"`, primero hay que abrir el proyecto en el editor o ejecutar `godot --headless --path . --import`.

Para abrir la demo, abre `tests/board/board_demo.tscn` en el editor de Godot y ejecuta la escena actual: **F6** en Windows/Linux o **Cmd+R** en macOS. También funciona el botón "Ejecutar escena actual" de arriba a la derecha. Desde la terminal:

```bash
godot --path . res://tests/board/board_demo.tscn
```

Controles (también hay botones en el panel):

- Clic izquierdo: selecciona y mueve.
- Clic derecho: bloquea una casilla.
- Q / E o arrastrar con la rueda presionada: giran la cámara.
- Rueda del mouse: zoom.
- V: alterna entre la vista de juego y una vista panorámica del paisaje.
- Espacio: paso del cazador.
- C: catástrofe en una casilla al azar.
- R: reinicia.
- Teclas 1–4: cambian de bioma (Páramo, Amazonía, Santuario, Clásico).

La demo se juega con las reglas FIDE reales. El rival automático es provisional (la IA real es del módulo de simulación) y se puede apagar para mover ambos bandos.

Al abrir la demo, la cámara hace una entrada cinematográfica: parte de una vista panorámica y baja hasta el tablero (`-- --no-intro` la omite). Cada bioma tiene su propio entorno:

| Bioma | Entorno |
|---|---|
| Páramo | Laguna, frailejonal, pajonal dorado, neblina y cóndores |
| Amazonía | Río, selva con palmas de cera, claro deforestado con tocones, luciérnagas, guacamayas y mariposas morpho |
| Santuario | Tierra seca y quemada, árboles muertos, retamo, columnas de humo, brasas, gallinazos e hipopótamos en una charca |
| Clásico | Estudio sobrio |

En la ambientación aparecieron dos detalles del renderer de compatibilidad que conviene saber:

- **Partículas.** Para que respeten su tamaño, el material debe usar `BILLBOARD_ENABLED` con `billboard_keep_scale = true`. Con `BILLBOARD_PARTICLES` todas se dibujan de 1 metro.
- **Agua turbia.** Necesita poca reflectividad (`SPECULAR` bajo). Si no, el reflejo del cielo la hace ver gris.

## Decisiones pendientes para el equipo

1. **El juego ahora es 3D.** Biomas (Integrante 4) e integración (Integrante 5) deben trabajar con escenas 3D. El HUD sigue siendo 2D.
2. **¿Qué significa "casilla bloqueada"?** El tablero la marca y la dibuja, pero no impide mover piezas ahí. El módulo de piezas debe decidir si una pieza puede entrar a una casilla bloqueada.
3. **¿El cazador ocupa la casilla?** Se modeló como un ocupante más, siguiendo el ejemplo del documento ("la casilla e5 queda ocupada por el cazador"). Falta definir si una pieza puede capturarlo.
4. **El cazador en el borde.** El documento no dice qué pasa si el paso aleatorio sale del tablero (quedarse quieto o volver a sortear). Lo decide el módulo de simulación. El tablero ofrece `is_inside()` y `get_orthogonal_neighbors()` para cualquiera de las dos opciones.
