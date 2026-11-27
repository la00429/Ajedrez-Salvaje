# Pruebas

Desde la raíz del proyecto:

```bash
godot --headless --path . --script res://tests/pieces/test_rules.gd
godot --headless --path . --script res://tests/board/test_board.gd
godot --headless --path . --script res://tests/simulation/test_simulation.gd
godot --headless --path . --script res://tests/ui/test_main_menu.gd
godot --headless --path . --script res://tests/integration/test_integration.gd
godot --headless --path . --script res://tests/audio/test_audio_manager.gd
```

Cada suite termina con `N comprobaciones, M fallidas`. Un código de salida cero
no basta: si un script no compila, Godot también sale con cero. Si aparece
`Could not find type ...`, primero ejecutar `godot --headless --path . --import`.

| Suite | Cubre |
|---|---|
| `test_rules.gd` | Movimientos, jaque, mate, ahogado, enroque, captura al paso, promoción, FEN, perft, ocupantes neutrales, conteo y material |
| `test_board.gd` | Coordenadas, ocupación, rayos, resaltados, vecindades, temas, animaciones y giro del tablero |
| `test_simulation.gd` | Generadores, Monte Carlo, dinámica de sistemas, cola M/M/1, caminata, agente cazador, niveles, victoria y motor completo, incluida la partida de ejemplo del documento de preproducción |
| `test_main_menu.gd` | Menú principal y navegación |
| `test_integration.gd` | Integración de partida completa (Rol 5): inicialización, ronda ambiental acoplada, alternancia y giro de turnos, vivero M/M/1, nivel 3 (retroexcavadora y tala) y condiciones de victoria |
| `test_audio_manager.gd` | Autoload, cinco buses, carga de los 31 recursos y controles de volumen/mute |

## Manuales

Abrir `scenes/main/Main.tscn` o `scenes/ui/MainMenu.tscn` (F6 o F5) para jugar la partida completa integrada. Para revisar tablero, piezas y ambientación aisladas se puede usar `tests/board/board_demo.tscn`.
