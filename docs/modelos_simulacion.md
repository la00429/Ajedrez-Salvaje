# Modelos de simulación

Esta capa todavía no tiene implementaciones en `scripts/simulation/`; por eso
las interfaces siguientes son contratos de trabajo, no funcionalidades
terminadas. No se fijan tasas, probabilidades ni unidades que el diseño no
haya definido.

| Componente | Propósito | Entradas mínimas | Salida |
|---|---|---|---|
| Generador pseudoaleatorio | Fuente reproducible | semilla y rango solicitado | secuencia o muestra |
| Monte Carlo | Estimar resultados por repeticiones | estado, número de réplicas, generador | estimación y dispersión |
| Balance hídrico | Actualizar disponibilidad de agua | estado inicial y consumos/eventos definidos | estado hídrico |
| Cola M/M/1 | Modelar el vivero | llegadas, servicio y capacidad según diseño | longitud/espera/estado |
| Caminata aleatoria | Mover un agente | posición, semilla y vecinos válidos | nueva posición |
| ABM | Simular agentes con reglas locales | agentes, vecindad, orden y pasos | estados y eventos |

## Reglas de implementación

El generador debe aceptar semilla para pruebas. Monte Carlo debe reportar el
número de muestras y no convertir una estimación en una certeza. El balance
hídrico debe conservar unidades y límites explícitos. M/M/1 debe separar
eventos de llegada y servicio. La caminata debe resolver explícitamente el
borde. ABM debe usar actualización determinista por fases o documentar el
orden aleatorio.

## Integración

El motor recibe un estado de nivel y devuelve un resultado inmutable o
serializable. El gestor decide cuándo ejecutarlo; el HUD solo muestra sus
resultados. Las señales propuestas son `simulation_started`,
`simulation_updated(result)` y `simulation_finished(result)`, pendientes de
aprobación.

## Pruebas

Probar semilla repetida, rangos y bordes del generador; Monte Carlo con casos
degenerados; conservación del balance; cola vacía y saturada; caminata en
esquinas; y ABM con cero agentes. Los parámetros concretos y unidades deben
provenir del diseño ambiental antes de escribir tests numéricos.