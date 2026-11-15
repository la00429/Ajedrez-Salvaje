# Integrante 3 — Motor de simulación

## Objetivo y alcance

Implementar los seis componentes descritos en
[`../modelos_simulacion.md`](../modelos_simulacion.md), con semillas
reproducibles, resultados tipados y sin modificar directamente las reglas
FIDE ni nodos visuales.

## Archivos y clases

Crear `scripts/simulation/` y sus pruebas en `tests/simulation/`. Proponer
`RandomSource`, `MonteCarloModel`, `WaterBalance`, `NurseryQueue`, `RandomWalk`
y `AgentModel`, además de un resultado común. Cada clase debe documentar
entradas, salidas, unidades, límites y semilla; no inventar valores.

## Dependencias y API

Consume geometría pública de `Board`, estado consultable de `ChessMatch` y
configuración del nivel. Entrega resultados a integración; HUD recibe solo
datos calculados. El vivero debe distinguir `capture` de `harvest`.

## Orden de implementación

1. Contratos y tipos de resultado.
2. Generador reproducible.
3. Monte Carlo y pruebas.
4. Balance hídrico y cola.
5. Caminata y ABM con bordes definidos.
6. Adaptador de integración y señales aprobadas.

## Pruebas y aceptación

Probar repetibilidad, casos vacíos, saturación, esquinas y cero agentes.
Aceptar solo si no hay constantes ambientales inventadas, los resultados son
reproducibles, las unidades están declaradas y la integración no toca nodos
directamente.

## Entrega

Usar rama `feature/simulation-*`, abrir Pull Request hacia `develop`, incluir
pruebas headless, ejemplo de consumo y actualización de [modelos](../modelos_simulacion.md).