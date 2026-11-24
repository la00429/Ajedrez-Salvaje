# Pruebas

Desde la raíz del proyecto:

```bash
godot --headless --path . --script res://tests/pieces/test_rules.gd
godot --headless --path . --script res://tests/board/test_board.gd
godot --headless --path . --script res://tests/simulation/test_simulation.gd
godot --headless --path . --script res://tests/ui/test_main_menu.gd
```

Cada suite termina con `N comprobaciones, M fallidas`. Un código de salida cero
no basta: si un script no compila, Godot también sale con cero. Si aparece
`Could not find type ...`, primero ejecutar `godot --headless --path . --import`.

| Suite | Cubre |
|---|---|
| `test_rules.gd` | Movimientos, jaque, mate, ahogado, enroque, captura al paso, promoción, FEN, perft, ocupantes neutrales, conteo y material |
| `test_board.gd` | Coordenadas, ocupación, rayos, resaltados, vecindades, temas, animaciones y giro del tablero |
| `test_simulation.gd` | Generadores, Monte Carlo, dinámica de sistemas, cola M/M/1, caminata, agente cazador, niveles, victoria y motor completo, incluida la partida de ejemplo del documento de preproducción |
| `test_main_menu.gd` | Menú principal |

## Manuales

Abrir `tests/board/board_demo.tscn` (F6) para revisar tablero, piezas y
ambientación en el renderer GL Compatibility. Las pruebas de integración de la
partida completa son del integrante 5 (`tests/integration/`).
