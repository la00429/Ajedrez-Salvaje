# Arquitectura

## Principios

El proyecto separa las reglas puras de ajedrez, la representación 3D, la
simulación ambiental y la interfaz. Las reglas no dependen de simulación ni de
nodos visuales; la integración coordina los módulos y traduce eventos.

```mermaid
flowchart TD
    Main[Main / GameManager] --> Turn[TurnManager]
    Turn --> Match[ChessMatch]
    Match --> Position[ChessPosition]
    Match --> Validator[MovementValidator]
    Match --> Board[Board 3D]
    Board --> Cell[Cell]
    Board --> Pieces[ChessPiece]
    Turn --> Level[LevelManager]
    Turn --> Engine[SimulationEngine]
    Engine --> Water[Agua y vivero por jugador]
    Engine --> Hunter[Agente cazador]
    Engine --> Excavator[Retroexcavadora]
    Turn --> Victory[VictoryManager]
    Victory --> Rules[VictoryRules]
    Turn --> HUD[GameHUD]
```

## Módulos y responsabilidades

| Módulo | Responsabilidad | No debe hacer |
|---|---|---|
| `Board` | Matriz 8 × 8, ocupación, coordenadas, entrada y resaltados | Validar jaque o movimientos FIDE |
| `ChessPosition` | Estado serializable de la partida, FEN, turno y derechos | Crear nodos 3D |
| `MovementValidator` | Generar y validar jugadas legales y estados finales | Leer parámetros ambientales |
| `ChessMatch` | Sincronizar reglas con `Board` y emitir jugadas | Decidir objetivos de nivel |
| Simulación | Clima, agua y vivero por jugador, cazador, retroexcavadora, niveles y condiciones de victoria | Mover nodos o alterar reglas FIDE |
| Bioma/UI | Escena, tema, HUD y presentación | Calcular reglas o simulaciones |
| Integración | Orden de fases, niveles, victoria/derrota y señales | Duplicar lógica de piezas |

## Flujo de datos y eventos

Cada ronda empieza con `SimulationEngine.run_round`, que devuelve un
`RoundResult`; el gestor aplica esos cambios al tablero y llama a
`ChessMatch.sync()`. Después juegan los dos jugadores: `Board.cell_clicked`
entrega una coordenada, el gestor consulta `ChessMatch.legal_moves_from` y, si
el destino es legal, llama a `ChessMatch.play` y gira el tablero con
`Board.orient_to_side`. Tras cada jugada y cada ronda se evalúa
`SimulationEngine.verdict`.

Las señales son eventos, no almacenamiento de estado. El estado canónico de
ajedrez es `ChessPosition`; el estado visual canónico es la ocupación de
`Board`; el estado ambiental debe pertenecer al motor de simulación.

## Dependencias

`Board` puede funcionar sin reglas. `MovementValidator` depende de
`ChessPosition` y de utilidades geométricas de `Board`. `ChessMatch` depende de
ambos. Simulación y UI deben consumir contratos de integración, no acceder a
campos privados. Las escenas de bioma pueden cambiar `BoardTheme` sin cambiar
la legalidad de una jugada.