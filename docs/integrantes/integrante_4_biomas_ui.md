# Integrante 4 — Biomas e interfaz

## Alcance

Ambientación del bioma, HUD y menú para el juego de **dos jugadores** con
niveles dentro de una misma partida. La interfaz solo muestra datos: no
calcula agua, clima ni victoria.

## Lo que ya existe

| Archivo | Contenido |
|---|---|
| `scenes/ui/MainMenu.tscn`, `scripts/ui/main_menu.gd` | Menú principal |
| `scenes/ui/GameHUD.tscn`, `scripts/ui/game_hud.gd` | HUD sin recuadros con métodos `set_*` y señales |
| `scripts/ui/ui_style.gd`, `scenes/ui/glass.gdshader`, `scripts/ui/hud_icon.gd` | Estilos e íconos |
| `scripts/board/board_theme.gd` | Colores del tablero por bioma |
| `tests/board/demo_environment.gd` y relacionados | Ambientaciones de ejemplo (Páramo, Amazonía, Santuario) |

## Lo que cambia

### Bioma

- **Un solo bioma base, el Páramo**, en `scenes/biomes/Paramo.tscn`, a partir de
  `tests/board/demo_environment.gd`. Ya no hay un bioma por nivel.
- Opcional: intensificar la ambientación al subir de nivel (más niebla en el
  nivel 2, tierra removida en el 3). No cambia reglas.

### HUD

| Necesidad | Detalle |
|---|---|
| Agua de cada jugador | Dos barras. Hoy `set_ecosystem(agua, clima, vivero)` muestra un solo ecosistema: hay que extenderlo a dos (por ejemplo `set_ecosystem(side, agua, vivero)` y `set_climate(texto)`) |
| Turno | "Jugador 1" / "Jugador 2" en lugar de "Tu turno" |
| Nivel | Mostrar el nivel actual y llamar `play_level_intro()` cuando `RoundResult.level_started` sea verdadero |
| Fin de partida | Texto según `Verdict.reason`: jaque mate, rey destruido, ahogado, colapso hídrico, colapso de ambos, ronda final por agua, por material o tablas |
| Menú de pruebas (F1) | Quitar "rival automático"; ya no existe rival por IA |
| Créditos | Completar nombres en `CREDITS` de `main_menu.gd` |

El HUD es 2D sobre la escena, así que **no gira** con el tablero.

### Menú

"Jugar" inicia una sola partida; ya no hay elección de nivel.

## Datos que recibe

Integración le pasa `RoundResult` y `Verdict` del motor de simulación (ver
[`integrante_3_simulacion.md`](integrante_3_simulacion.md)):

- `climate_label()`;
- `water_percent(side)` y `queue_lengths[side]`;
- `level` y `level_started`;
- `Verdict.reason` y `Verdict.winner`.

## Pruebas

```bash
godot --headless --path . --script res://tests/ui/test_main_menu.gd
```

Comprobar a mano el HUD con dos ecosistemas, la intro de cada nivel y la
pantalla de fin para cada causa.
