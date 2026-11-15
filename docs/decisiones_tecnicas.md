# Decisiones técnicas

| Decisión | Motivo | Alternativas | Estado |
|---|---|---|---|
| Ajedrez completo de seis piezas | El alcance confirmado reemplazó el set reducido | Mantener peones/caballos/rey | Aprobada |
| Tablero 3D y HUD 2D | Coincide con escenas y scripts existentes | Tablero 2D | Aprobada |
| Reglas separadas de nodos | Permite perft, IA y pruebas deterministas | Reglas dentro de piezas visuales | Aprobada |
| `ChessMatch` como puente | Evita que UI o simulación muten reglas directamente | Acceso directo al tablero | Aprobada |
| Generador pseudoaleatorio como componente compartido | Monte Carlo, caminata y ABM necesitan reproducibilidad | Un RNG distinto por modelo | Propuesta |
| Tres niveles | Alcance del encargo | Un nivel demostrativo | Aprobada |
| Captura y cosecha entran al vivero con origen distinto | Requisito de diseño | Un contador común | Aprobada |
| Orden exacto de fases de turno | Aún no existe gestor en el árbol actual | Secuencia de `flujo_de_turnos.md` | Pendiente |
| Tablas FIDE completas | El código aún no cubre 50 movimientos, repetición ni material | Implementarlas en `ChessPosition` | Pendiente |

Las decisiones propuestas no deben presentarse como implementadas. Cualquier
cambio de reglas debe actualizar este registro, `reglas_del_juego.md` y sus
pruebas.
