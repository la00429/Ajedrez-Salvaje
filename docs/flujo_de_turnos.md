# Flujo de turnos

El orden completo de las fases ambientales no está implementado en una escena
de integración. La siguiente secuencia es una **propuesta pendiente de
aprobación**, mientras que las operaciones de ajedrez sí están respaldadas por
`ChessMatch`.

1. `TurnManager` comprueba que la partida no esté pausada ni terminada.
2. Actualiza el HUD con bando, número y jaque.
3. Ejecuta la fase ambiental definida para el nivel.
4. Ejecuta las simulaciones y publica un resultado.
5. Procesa capturas voluntarias/cosechas y entradas del vivero distinguiendo
   su origen.
6. Habilita `Board.input_enabled` durante el turno del jugador.
7. Selecciona una pieza, consulta `legal_moves_from` y resalta destinos.
8. Al hacer clic en un destino, llama a `ChessMatch.play`.
9. Registra la jugada y deshabilita la entrada.
10. Ejecuta el movimiento del rival/agentes mediante contratos de simulación.
11. Llama a `ChessMatch.sync()` si una fase externa cambió el tablero.
12. Evalúa jaque, mate, ahogado, rey perdido, objetivo ambiental y derrota.
13. Si no termina, incrementa el turno y repite.

Una captura de ajedrez debe registrarse como captura; una cosecha voluntaria
debe registrarse como evento distinto. El vivero no debe inferir el origen por
el tipo de nodo. El gestor debe emitir explícitamente ambos eventos.

## Pausa y fin

Pausa bloquea entrada y simulación sin destruir estado. Fin de partida
deshabilita tablero, muestra `GameHUD.show_game_over` y permite reiniciar o
volver al menú. Las condiciones ambientales concretas siguen pendientes.