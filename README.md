# Ajedrez Salvaje: Biomas de Colombia

Videojuego 3D en Godot 4 que combina una partida de ajedrez completo con
biomas colombianos y modelos de simulación ambiental. La documentación de
implementación está en [`docs/`](docs/README.md).

## Alcance actual

- Tablero 8 × 8 y piezas completas: peón, caballo, alfil, torre, dama y rey.
- Reglas FIDE implementadas en `ChessPosition` y `MovementValidator`: jugadas
  legales, capturas, jaque, mate, ahogado, enroque, captura al paso y
  promoción.
- Puente entre reglas y representación 3D mediante `ChessMatch`.
- Tablero, casillas, resaltados, temas visuales y HUD funcionales.
- Tres niveles/biomas previstos; sus parámetros y condiciones siguen
  pendientes de validación del diseño ambiental.
- Modelos de simulación previstos: generador pseudoaleatorio, Monte Carlo,
  balance hídrico, cola M/M/1, caminata aleatoria y ABM.

Lo que no exista en `scripts/`, `scenes/`, `resources/` o `tests/` se
considera pendiente, aunque esté descrito como objetivo en la documentación.

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

## Pruebas existentes

Desde la raíz:

```bash
godot --headless --path . --script res://tests/pieces/test_rules.gd
godot --headless --path . --script res://tests/board/test_board.gd
```

El primer comando imprime el número de comprobaciones y fallos, e incluye
perft e integración `ChessMatch`-`Board`. Las pruebas ambientales/UI existentes
pueden ejecutarse como escenas según se describe en [`docs/pruebas.md`](docs/pruebas.md).

## Documentación

- [Mapa documental](docs/README.md)
- [Arquitectura](docs/arquitectura.md)
- [Especificación técnica](docs/especificacion_tecnica.md)
- [Reglas del juego](docs/reglas_del_juego.md)
- [Modelos de simulación](docs/modelos_simulacion.md)
- [Niveles y biomas](docs/niveles_y_biomas.md)
- [Flujo de turnos](docs/flujo_de_turnos.md)
- [Contratos de integración](docs/integracion_modulos.md)
- [Pruebas](docs/pruebas.md)
- [Decisiones técnicas](docs/decisiones_tecnicas.md)
- [Trabajo con Git](docs/convenciones_git.md)
- [Guías de integrantes](docs/integrantes/README.md)

## Estado y contribución

La rama `main` representa la versión estable, `develop` integra trabajo y las
ramas `feature/*` y `docs/*` contienen cambios acotados. Consulta
[`docs/convenciones_git.md`](docs/convenciones_git.md) antes de abrir un Pull
Request. No se deben cambiar reglas de ajedrez desde el módulo ambiental.