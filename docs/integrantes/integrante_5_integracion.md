# Integrante 5 — Integración y progresión

## Objetivo

Construir la escena principal y coordinar turnos, niveles, simulación, HUD,
victoria/derrota y sincronización sin duplicar reglas.

## Archivos y escenas

Crear o completar `scripts/game/` (`GameManager`, `TurnManager`, `LevelManager`
y `VictoryManager`) y `scenes/main/Main.tscn`. Integrar `Board.tscn`,
`ChessPiece.tscn`, una cámara 3D, bioma y `GameHUD.tscn`.

## Contratos

Usar `ChessMatch` para toda jugada, `Board.input_enabled` para bloquear entrada,
`ChessMatch.sync()` después de cambios externos y los métodos/señales de
`GameHUD`. Mantener eventos de vivero separados por origen.

## Orden recomendado

1. Instanciar tablero, cámara y HUD.
2. Crear `ChessMatch` y posición inicial.
3. Conectar clics, selección y `move_played`.
4. Añadir turnos y rival provisional.
5. Añadir simulación inyectable y vivero.
6. Añadir `LevelManager`, condiciones aprobadas y transiciones.
7. Añadir pantallas de fin y pruebas de sistema.

## Criterios de aceptación

Una jugada ilegal nunca cambia estado; una legal sincroniza tablero y
posición; pausa bloquea entradas; captura y cosecha llegan con eventos
distintos; `sync()` se ejecuta tras acciones ambientales; cada nivel carga su
tema; y cada condición de fin se muestra una sola vez.

## Pruebas y Pull Request

Crear pruebas en `tests/integration/` para flujo de clic, turno, pausa,
captura, reinicio y transición. Entregar rama `feature/integration-*` hacia
`develop` con contratos actualizados y salida de pruebas headless.