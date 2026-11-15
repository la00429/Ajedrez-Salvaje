# Integrante 3 — Motor de simulación

## Objetivo y alcance

Implementar los seis componentes descritos en
[`../modelos_simulacion.md`](../modelos_simulacion.md), reutilizando el
generador pseudoaleatorio desarrollado en el taller anterior. Todos los
modelos que necesiten azar deben recibir ese generador (o una interfaz
compatible) por inyección, conservar semillas reproducibles y devolver
resultados tipados, sin modificar directamente las reglas FIDE ni nodos
visuales.

## Archivos y clases

Crear `scripts/simulation/` y sus pruebas en `tests/simulation/`. El generador
del taller debe quedar como la única fuente de aleatoriedad del módulo
(por ejemplo, adaptándolo a `RandomSource` si su API tiene otro nombre), no
duplicándolo dentro de cada modelo. Proponer `MonteCarloModel`,
`WaterBalance`, `NurseryQueue`, `RandomWalk` y `AgentModel`, además de un
resultado común. Cada clase debe documentar entradas, salidas, unidades,
límites y si consume aleatoriedad; no inventar valores.

La correspondencia mínima es:

| Componente | ¿Usa el generador? | Uso |
|---|---|---|
| Monte Carlo | Sí | Muestrear cada réplica y evento estocástico |
| Balance hídrico | No necesariamente | Actualizar consumos y eventos recibidos |
| Cola M/M/1 | Solo si el diseño modela llegadas/servicios aleatorios | Muestrear eventos; si recibe trazas, debe ser determinista |
| Caminata aleatoria | Sí | Elegir un vecino válido |
| ABM | Sí, cuando sus reglas incluyen azar | Orden, decisiones o eventos de agentes |
| Adaptador de integración | No | Coordinar modelos y propagar semillas/resultados |

El balance hídrico y la cola no deben introducir azar por su cuenta. Si una
configuración los hace estocásticos, deben recibir el mismo generador
compartido o un subgenerador derivado explícitamente de la semilla de la
simulación.

## Dependencias y API

Consume geometría pública de `Board`, estado consultable de `ChessMatch` y
configuración del nivel. Entrega resultados a integración; HUD recibe solo
datos calculados. El vivero debe distinguir `capture` de `harvest`.

## Orden de implementación

1. Localizar el código y la API del generador del taller anterior y definir su
   adaptador, sin reemplazarlo por otro RNG.
2. Contratos y tipos de resultado.
3. Monte Carlo y pruebas con una instancia inyectada del generador.
4. Balance hídrico y cola, deterministas salvo configuración estocástica.
5. Caminata y ABM con el mismo mecanismo de aleatoriedad y bordes definidos.
6. Adaptador de integración y señales aprobadas.

## Pruebas y aceptación

Probar que una misma semilla del generador del taller produce la misma
secuencia y los mismos resultados en Monte Carlo, caminata y ABM; también
probar rangos, casos vacíos, saturación, esquinas y cero agentes. Verificar
que dos modelos no compartan accidentalmente un estado mutable cuando deban
usar subsemillas reproducibles. Aceptar solo si no hay constantes ambientales
inventadas, las unidades están declaradas y la integración no toca nodos
directamente.

## Entrega

Usar rama `feature/simulation-*`, abrir Pull Request hacia `develop`, incluir
pruebas headless, ejemplo de consumo y actualización de [modelos](../modelos_simulacion.md).