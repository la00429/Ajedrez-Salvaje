# Integrante 4 — Biomas e interfaz

Este documento describe lo que ya existe en esta área y lo que falta.

## Lo que ya existe

| Archivo | Contenido |
|---|---|
| `scenes/ui/MainMenu.tscn`, `scripts/ui/main_menu.gd` | Menú principal (escena de arranque): Jugar con elección de nivel, Cómo jugar, Créditos y Salir |
| `scenes/ui/GameHUD.tscn`, `scripts/ui/game_hud.gd` | `GameHUD`: interfaz de la partida |
| `scripts/ui/ui_style.gd`, `scenes/ui/glass.gdshader`, `scripts/ui/hud_icon.gd` | Estilos compartidos. El HUD usa el tema **mínimo, sin recuadros** (`UiStyle.build_minimal()`): texto con contorno suave y botones de texto. El menú usa **vidrio esmerilado** (`UiStyle.build()` y `UiStyle.glass_panel()`). `hud_icon.gd` dibuja los íconos (gota, clima, brote, pausa…) por código |
| `scripts/board/board_theme.gd` | Colores del tablero por bioma (Páramo, Amazonía, Santuario, Clásico) |
| `tests/board/demo_environment.gd` y relacionados | Ambientación 3D de ejemplo por bioma: terreno, agua, vegetación, niebla, fauna. Sirve de base para `scenes/biomes/` |

## GameHUD

El HUD **no tiene recuadros**: el texto va directo sobre la escena, con sombra y contorno suaves y un degradado leve arriba y abajo. **Solo muestra información**, no calcula nada. El juego le pasa los datos con métodos `set_*` y escucha sus señales.

Qué hay en pantalla:
- **Nivel:** aparece en grande al empezar (`play_level_intro()`) y se encoge a una línea arriba a la izquierda. El objetivo se ve unos segundos y al pasar el mouse por esa línea.
- **Turno:** un punto y "Tu turno" sobre el borde superior del tablero (`set_turn_anchor()`). El tablero acompaña con un brillo leve en el filete del marco (`board.set_frame_glow()`).
- **Ecosistema:** íconos pequeños de agua (con barra), clima y vivero, arriba a la derecha. **Los valores pendientes no se muestran.**
- **Jugadas:** cajón a la derecha, cerrado por defecto (Tab o ícono de lista).
- **Íconos discretos arriba a la derecha:** jugadas, vista panorámica y pausa.
- **Menú de pruebas (F1):** paso del cazador, catástrofe, reiniciar y rival automático. Oculto para el jugador.
- **Pausa (Esc) y fin de partida:** a pantalla completa, sin cajas, con botones de texto.
- **Capturas:** no van en el HUD. La demo las coloca en 3D, en miniatura, a los lados del tablero.

### Métodos

```gdscript
hud.set_level(1, "Páramo en Alerta", "Reserva de Sumapaz", "Objetivo: ...")
hud.play_level_intro()
hud.set_turn(side, numero_de_jugada, en_jaque)          # side: 0 jugador, 1 rival
hud.set_turn_anchor(posicion_en_pantalla, visible)     # borde superior del tablero
hud.set_ecosystem(72.0, "Lluvia", 1)                   # sin argumentos = nada visible
hud.add_move(side, "Cf3+")
hud.clear_moves()
hud.toggle_moves()
hud.toggle_debug()
hud.set_hover_info("E4 · Cazador furtivo")
hud.show_banner("¡Jaque!", &"alert")                     # &"info", &"alert" o &"gold"
hud.show_game_over("¡Victoria!", "Jaque mate · Páramo en Alerta", &"victory")
hud.set_turn_message("Jaque mate")
hud.apply_board_theme(board.board_theme)               # color de acento del bioma
hud.set_paused(true)
```

### Señales

`hunter_step_requested`, `catastrophe_requested`, `view_toggle_requested`, `restart_requested`, `menu_requested`, `auto_rival_toggled(enabled)`, `theme_selected(theme_name)` y `pause_changed(paused)`.

La demo (`tests/board/board_demo.gd`) muestra cómo conectarlo todo, incluidas las capturas en 3D y el brillo del marco.

## Lo que falta

- **Datos del ecosistema.** La tarjeta muestra "pendiente" hasta que el módulo de simulación (integrante 3) llame a `hud.set_ecosystem(A(t), clima, Lq)` en cada turno.
- **Escenas de biomas** `Paramo.tscn`, `Amazonia.tscn` y `Santuario.tscn` en `scenes/biomes/`. Pueden partir de `tests/board/demo_environment.gd`. Las notas de iluminación para el renderer de compatibilidad están en `docs/integrantes/integrante_1_tablero.md`.
- **Configuraciones** `paramo_config.tres`, `amazonia_config.tres` y `santuario_config.tres` en `resources/biomes/`, con los parámetros de simulación de cada nivel.
- **Nombres en los créditos** del menú (`CREDITS` en `scripts/ui/main_menu.gd`).
