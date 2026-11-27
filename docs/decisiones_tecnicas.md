# Decisiones técnicas

## Vigentes

| Decisión | Motivo |
|---|---|
| Ajedrez completo de seis piezas | El alcance confirmado reemplazó el set reducido |
| Tablero 3D y HUD 2D | Coincide con escenas y scripts existentes |
| Reglas separadas de nodos; `ChessMatch` como puente | Permite perft, pruebas deterministas y que la simulación no mute reglas |
| **Dos jugadores en el mismo equipo, sin IA rival** | La complejidad del juego anterior excedía los requisitos del docente. Además el rival por agentes jugaba mal: contra un jugador que siempre captura perdía casi tantas piezas como un rival al azar (13.6 frente a 14.8 por partida) |
| **El tablero gira 180° al cambiar de turno** | Cada jugador ve desde su lado. Solo gira el nodo del tablero: coordenadas y reglas no cambian y los clics funcionan porque `ray_to_coord` usa la transformación global |
| **Tres niveles dentro de una misma partida, cada 10 rondas** | Los modelos se activan de forma progresiva sin escenas separadas por nivel: nivel 1 cazador, nivel 2 clima severo, nivel 3 retroexcavadora |
| **Un solo bioma base** | Quitar el cambio de bioma por nivel baja el trabajo de escenas; la ambientación puede intensificarse sin cambiar reglas |
| **Se eliminan hipopótamos, retamo, palma de cera y un segundo cazador** | Agentes y modelos 3D nuevos que no aportan un tema del curso adicional |
| **El cazador es el único agente** | Agente heurístico simple: va hacia la pieza más cercana. Los apuntes definen el modelo por agente (entorno, percepción, estado interno, política, acción) y los ejemplos del profesor son un solo agente en su entorno; no se exigen agentes que interactúen |
| **La caminata aleatoria pasa a la retroexcavadora** | Al volver agente al cazador, la caminata necesitaba otro portador. La retroexcavadora tala la casilla que deja y achica el tablero, lo que también empuja la partida a terminar |
| **Ecosistema por jugador y clima compartido** | Cada jugador tiene su agua y su vivero; un mismo evento climático afecta a ambos. Capturar frailejones rivales baja su condensación, lo que une ajedrez y ecosistema |
| **Tres condiciones de victoria en orden: ajedrez, colapso hídrico, ronda final** | La ronda final (30) evita partidas infinitas porque las tablas FIDE por repetición o 50 jugadas no están implementadas; el material desempata |
| **La fase ambiental corre una vez por ronda, antes de las dos jugadas** | Sigue el orden del documento de preproducción (ambiente, regeneración, desestabilizador, jugadas) |
| **Generadores: congruencia mixta y Lehmer, con subflujos por semilla** | Son los del Taller 1. La Tabla 2 del documento asigna Lehmer a la caminata. Los subflujos derivados de la semilla hacen la partida reproducible sin que un modelo altere a otro |
| **Modelos con la estructura enseñada en clase** | Matriz de Monte Carlo con rangos de r, variables de estado y de flujo con Euler, simulación de eventos discretos para la cola, ecuación de estado de la caminata y entorno/política/recompensa para el agente |
| **Condiciones de victoria como lógica pura en `VictoryRules`** | Combinan reglas de ajedrez y agua; al ser funciones puras se prueban sin escena y el `VictoryManager` de integración solo las llama |
| **Código en inglés, documentación en español, comentarios mínimos** | El código se entiende por nombres y métodos cortos de una sola responsabilidad |

## Eliminadas en esta revisión

| Antes | Por qué se quitó |
|---|---|
| Rival controlado por agentes (`AgentModel`) | Ya no hay rival automático |
| Pronóstico de supervivencia por Monte Carlo | No lo pedía el diseño |
| Señales del motor (`simulation_started`, etc.) | No estaban aprobadas; el motor devuelve resultados |
| Documentos `flujo_de_turnos.md`, `niveles_y_biomas.md`, `integracion_modulos.md` | Describían el juego de un jugador contra la IA y tres niveles separados |

## Pendientes de aprobación del equipo

- Valores supuestos: clima severo, pérdida por catástrofe, capacidad del vivero,
  rondas por nivel, ronda final y borde de la retroexcavadora.
- Actualizar el documento de preproducción (secciones 3, 4 y 5) al juego de dos
  jugadores.
