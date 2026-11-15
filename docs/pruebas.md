# Pruebas

## Unitarias

### Ajedrez

Usar `tests/pieces/test_rules.gd` para movimientos de las seis piezas,
capturas, jaque, mate, ahogado, enroques, captura al paso, promociones, FEN y
reglas de cazador/casillas bloqueadas. Mantener perft de posiciones conocidas.

### Tablero

Usar `tests/board/test_board.gd` para coordenadas, límites, ocupación,
movimiento, retiro, resaltados, vecindades y conversión 3D. Desactivar
animaciones en pruebas.

### Simulación

Añadir pruebas reproducibles por semilla, límites, conservación de unidades,
cola vacía/saturada, bordes y cero agentes. No fijar números que no estén en la
especificación ambiental.

## Integración

Comprobar que un clic solo ejecuta una jugada legal, que `ChessMatch` y
`Board` conservan la misma posición, que una captura llega al vivero con
origen `capture`, que una cosecha llega con origen `harvest`, y que
`ChessMatch.sync()` repara cambios externos.

## Sistema y UI

Ejecutar escenas de demo, comprobar carga de cada bioma, pausa, reinicio,
transición, HUD, pantallas de victoria/derrota y bloqueo de entrada durante
turnos rivales. Validar visualmente GL Compatibility.

## Comandos

```bash
godot --headless --path . --script res://tests/pieces/test_rules.gd
godot --headless --path . --script res://tests/board/test_board.gd
```

Un código de salida cero no basta si el script no compiló: revisar siempre el
resumen `N comprobaciones, M fallidas`.
