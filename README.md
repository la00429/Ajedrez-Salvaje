# Ajedrez Salvaje: Biomas de Colombia

Videojuego 3D en Godot 4 para dos jugadores que combina una partida de
ajedrez completo con la fauna y flora del páramo colombiano y modelos de
simulación ambiental. La documentación de
implementación está en [`docs/`](docs/README.md).

## Alcance actual

- Ajedrez FIDE completo para dos jugadores; el tablero gira al cambiar de
  turno.
- Cada jugador tiene su reserva de agua y su vivero; tres niveles dentro de una
  misma partida.
- Motor de simulación con los modelos del curso: generadores congruenciales,
  Monte Carlo, dinámica de sistemas, cola M/M/1, caminata aleatoria 2D y un
  agente (el cazador furtivo).
- Tablero, piezas, menú y HUD funcionales; falta la escena de partida que una
  todo (integrante 5).

Las reglas completas están en [`docs/reglas_del_juego.md`](docs/reglas_del_juego.md).

## Tecnologías y requisitos

- Godot **4.7** (verificado en `project.godot`, característica `"4.7"`).
- GDScript.
- Renderer GL Compatibility.
- Git.

Instala Godot 4.7, clona el repositorio y abre la carpeta raíz desde el
Project Manager. Después ejecuta `scenes/ui/MainMenu.tscn` o presiona F6 para
la escena abierta. La escena principal configurada es
`scenes/ui/MainMenu.tscn`.

## Estructura

```text
assets/       audio, fuentes y sprites
scenes/       escenas Godot (tablero, piezas, UI y biomas)
scripts/      lógica GDScript por módulo
resources/    recursos configurables
tests/        demos y pruebas ejecutables
docs/         documentación técnica y guías por integrante
```

## Equipo

| Integrante | Módulo |
|---|---|
| 1 | Tablero y casillas |
| 2 | Piezas y reglas |
| 3 | Motor de simulación |
| 4 | Biomas e interfaz |
| 5 | Integración y progresión |

## Pruebas

Desde la raíz:

```bash
godot --headless --path . --script res://tests/pieces/test_rules.gd
godot --headless --path . --script res://tests/board/test_board.gd
godot --headless --path . --script res://tests/simulation/test_simulation.gd
godot --headless --path . --script res://tests/ui/test_main_menu.gd
godot --headless --path . --script res://tests/audio/test_audio_manager.gd
```

Detalles en [`docs/pruebas.md`](docs/pruebas.md).

## Documentación

- [Mapa documental](docs/README.md)
- [Arquitectura](docs/arquitectura.md)
- [Especificación técnica](docs/especificacion_tecnica.md)
- [Reglas del juego](docs/reglas_del_juego.md)
- [Modelos de simulación](docs/modelos_simulacion.md)
- [Pruebas](docs/pruebas.md)
- [Decisiones técnicas](docs/decisiones_tecnicas.md)
- [Trabajo con Git](docs/convenciones_git.md)
- [Guías de integrantes](docs/integrantes/README.md)

## Estado y contribución

La rama `main` representa la versión estable, `develop` integra trabajo y las
ramas `feature/*` y `docs/*` contienen cambios acotados. Consulta
[`docs/convenciones_git.md`](docs/convenciones_git.md) antes de abrir un Pull
Request. No se deben cambiar reglas de ajedrez desde el módulo ambiental.