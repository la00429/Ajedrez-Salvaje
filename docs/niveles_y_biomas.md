# Niveles y biomas

El alcance confirmado incluye tres niveles. El repositorio actual contiene
temas de tablero para `paramo`, `amazonia` y `santuario`, y demos ambientales
en `tests/board/`; no contiene todavía escenas de producción ni recursos de
configuración en `scenes/biomes/` y `resources/biomes/`.

| Nivel | Evidencia actual | Estado |
|---|---|---|
| Páramo | `BoardTheme` y demo ambiental con laguna, frailejonal, pajonal, niebla y cóndores | Visual de demo |
| Amazonía | tema y demo con río, selva, claro, luciérnagas, guacamayas y mariposas | Visual de demo |
| Santuario | tema y demo con tierra seca/quemada, humo, brasas, charca e hipopótamos | Visual de demo |

## Contrato de un nivel

Cada nivel debe declarar contexto, recursos, eventos, parámetros de simulación,
objetivo, derrota y transición en un recurso. Estos valores no están definidos
en el código revisado; deben aprobarse antes de convertirlos en condiciones
ejecutables. No se deben inventar tasas, coeficientes o metas.

## Integración visual

Al cargar un nivel, integración aplica el `BoardTheme`, instancia el entorno y
llama al HUD con número, título, lugar y objetivo. Simulación entrega métricas
al HUD mediante `set_ecosystem`; la UI no calcula victoria o derrota.

## Pendientes

Crear `Paramo.tscn`, `Amazonia.tscn`, `Santuario.tscn` y sus configuraciones
`.tres`; acordar eventos, parámetros, condiciones de victoria/derrota y reglas
de transición con el equipo.