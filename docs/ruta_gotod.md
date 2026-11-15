# TAREA: REORGANIZACIÓN Y DOCUMENTACIÓN TÉCNICA INTEGRAL DE AJEDREZ SALVAJE

Actúa como arquitecto de software, analista de requisitos y líder técnico especializado en videojuegos 2D desarrollados con Godot 4, GDScript, simulación computacional y desarrollo colaborativo con Git.

Necesito que realices una reorganización y documentación técnica integral del repositorio **Ajedrez-Salvaje**, disponible en el entorno actual de GitHub Codespaces.

No quiero únicamente recomendaciones: debes inspeccionar el repositorio y CREAR, COMPLETAR, ACTUALIZAR y ORGANIZAR directamente los archivos Markdown necesarios.

## 1. CONTEXTO DEL PROYECTO

Nombre: Ajedrez Salvaje: Biomas de Colombia.

Motor: Godot 4.

Lenguaje: GDScript.

Control de versiones: Git y GitHub.

Equipo: cinco integrantes.

Propósito: desarrollar un videojuego 2D que combine las reglas del ajedrez con modelos de simulación computacional y dinámicas ambientales relacionadas con los biomas colombianos.

El proyecto se encuentra en desarrollo colaborativo. Los integrantes tienen conocimientos de programación y Git, pero están comenzando a trabajar con Godot.

La documentación debe permitir que cada integrante comprenda qué debe desarrollar, dónde debe hacerlo, cómo debe programarlo y cómo integrar su trabajo con los demás.

## 2. CAMBIO FUNDAMENTAL DEL ALCANCE

Anteriormente se había definido una versión reducida del ajedrez, compuesta por peones, caballos y rey.

Esta decisión ha cambiado.

La nueva versión debe implementar el **ajedrez completo**, incluyendo:

- Peones.
- Caballos.
- Alfiles.
- Torres.
- Dama.
- Rey.

Se deben contemplar las reglas tradicionales:

- Movimientos legales.
- Capturas.
- Jaque.
- Jaque mate.
- Ahogado.
- Enroque corto y largo.
- Captura al paso.
- Promoción de peones.
- Tablas y condiciones de finalización.

No se debe conservar la restricción de piezas de la versión reducida.

También se mantienen las siguientes decisiones:

- Se desarrollarán los tres niveles del videojuego.
- El vivero recibirá elementos tanto de capturas como de cosechas voluntarias.
- Los dos mecanismos de ingreso deben distinguirse mediante su origen y sus eventos.
- Se conservarán los cinco modelos de simulación definidos para el proyecto.
- Se conservará la organización colaborativa de cinco integrantes.

## 3. PRIMERA FASE: AUDITORÍA DEL REPOSITORIO

Antes de modificar archivos:

1. Inspecciona la estructura completa del repositorio.
2. Examina el README principal.
3. Examina todos los documentos de la carpeta docs/.
4. Examina los archivos existentes dentro de docs/integrantes/.
5. Examina project.godot.
6. Examina las escenas y scripts existentes.
7. Examina los recursos y configuraciones existentes.
8. Identifica los archivos que contienen decisiones del diseño original.
9. Identifica documentación incompleta, duplicada, contradictoria o desactualizada.
10. Identifica funcionalidades ya implementadas que no deben documentarse como pendientes.

Si existe un PDF, documento de preproducción o especificación original dentro del repositorio, úsalo como fuente principal para verificar las mecánicas.

No inventes características que no estén respaldadas por el diseño.

Cuando exista una decisión nueva confirmada en este encargo, actualiza la documentación anterior para reflejarla.

Distingue siempre entre:

- Requisitos documentados.
- Decisiones confirmadas.
- Propuestas técnicas.
- Aspectos pendientes de validación.

No presentes propuestas como si fueran requisitos originales.

## 4. SEGUNDA FASE: ORGANIZACIÓN DOCUMENTAL

Conserva los archivos existentes que sean útiles y actualízalos en lugar de crear duplicados innecesarios.

La documentación debe quedar organizada de manera semejante a esta estructura, adaptándola a los archivos reales que ya existen:

```text
Ajedrez-Salvaje/
│
├── README.md
├── CONTRIBUTING.md
│
├── docs/
│   ├── README.md
│   ├── arquitectura.md
│   ├── especificacion_tecnica.md
│   ├── reglas_del_juego.md
│   ├── modelos_simulacion.md
│   ├── niveles_y_biomas.md
│   ├── flujo_de_turnos.md
│   ├── convenciones_git.md
│   ├── integracion_modulos.md
│   ├── pruebas.md
│   ├── decisiones_tecnicas.md
│   │
│   └── integrantes/
│       ├── README.md
│       ├── 01_tablero.md
│       ├── 02_piezas_y_reglas.md
│       ├── 03_simulacion.md
│       ├── 04_biomas_y_interfaz.md
│       └── 05_integracion_y_progresion.md
│
├── assets/
├── scenes/
├── scripts/
├── resources/
└── tests/
```

No muevas ni elimines archivos de código existentes por el simple hecho de que la estructura propuesta sea diferente.

Si ya existen nombres de archivos establecidos, conserva los nombres útiles y actualiza su contenido.

## 5. TERCERA FASE: DOCUMENTACIÓN GENERAL

Desarrolla los siguientes documentos con profundidad técnica.

### A. README.md

Debe incluir:

- Nombre del proyecto.
- Descripción.
- Objetivo general.
- Características.
- Alcance funcional.
- Tecnologías.
- Requisitos de instalación.
- Procedimiento para abrir el proyecto en Godot.
- Estructura del repositorio.
- Organización del equipo.
- Enlaces a la documentación.

### B. Arquitectura

Explica:

- Arquitectura modular.
- Responsabilidad de cada módulo.
- Dependencias.
- Comunicación entre módulos.
- Flujo de datos.
- Gestión de eventos.
- Responsabilidad de los gestores principales.

Incluye un diagrama Mermaid de arquitectura.

### C. Especificación técnica

Documenta:

- Versión de Godot que utiliza el proyecto, verificándola cuando sea posible.
- Lenguaje.
- Estructura de escenas.
- Estructura de scripts.
- Recursos.
- Convenciones de nombres.
- Uso de señales.
- Gestión de estados.
- Configuraciones por nivel.
- Criterios de calidad del código.

### D. Reglas del juego

Documenta el funcionamiento del ajedrez completo, las seis piezas, sus movimientos y las reglas especiales.

Explica cómo se representa el estado de una partida y cómo se valida la legalidad de los movimientos.

Separa las reglas tradicionales del ajedrez de las mecánicas ambientales propias del videojuego.

### E. Modelos de simulación

Documenta los cinco modelos identificados en el diseño:

1. Generador pseudoaleatorio.
2. Simulación Monte Carlo.
3. Balance hídrico.
4. Cola M/M/1 del vivero.
5. Caminata aleatoria.
6. Agentes autónomos mediante ABM.

IMPORTANTE: son seis componentes/modelos enumerados aquí; verifica el diseño original para determinar si el generador pseudoaleatorio se considera infraestructura de los demás modelos o un modelo independiente. No elimines ninguno.

Para cada uno explica:

- Objetivo.
- Fundamento.
- Entradas.
- Salidas.
- Variables.
- Parámetros.
- Algoritmo.
- Integración.
- Casos de prueba.

No inventes probabilidades, tasas, coeficientes ni unidades.

### F. Niveles y biomas

Documenta los tres niveles del videojuego.

Para cada uno explica, según el diseño disponible:

- Contexto ambiental.
- Recursos.
- Eventos.
- Parámetros de simulación.
- Condiciones de victoria.
- Condiciones de derrota.
- Diferencias con los otros niveles.

No inventes condiciones de victoria ni mecánicas ambientales si no están definidas.

### G. Flujo de turnos

Explica detalladamente:

- Inicio de turno.
- Actualización ambiental.
- Ejecución de simulaciones.
- Interacción con el vivero.
- Movimiento del jugador.
- Movimiento de agentes rivales.
- Finalización del turno.
- Evaluación de condiciones de victoria o derrota.

Verifica el orden real contra el diseño del proyecto. Si no está definido, presenta una propuesta claramente identificada como pendiente de aprobación.

### H. Integración de módulos

Este documento es especialmente importante.

Define los contratos entre los cinco integrantes:

- Señales.
- Métodos públicos.
- Parámetros.
- Tipos de datos.
- Eventos.
- Responsabilidades de cada módulo.

Incluye ejemplos de firmas GDScript cuando sea posible.

Evita que dos integrantes implementen funciones con responsabilidades duplicadas.

### I. Pruebas

Define pruebas para:

- Reglas del ajedrez.
- Movimientos legales e ilegales.
- Reglas especiales.
- Simulaciones.
- Integración.
- Transiciones de niveles.
- Condiciones de finalización.
- Interfaz.

Distingue pruebas unitarias, integración y pruebas de sistema.

### J. Decisiones técnicas

Registra:

- Decisión.
- Motivo.
- Alternativas.
- Consecuencias.
- Estado: aprobada, propuesta o pendiente.

Incluye expresamente el cambio de versión reducida a completa.

## 6. CUARTA FASE: INSTRUCCIONES INDIVIDUALES

Debes desarrollar cinco documentos independientes y suficientemente detallados.

No quiero que sean simples descripciones de responsabilidades.

Cada documento debe funcionar como una guía de trabajo para que el integrante pueda desarrollar su módulo sin tener que preguntarme constantemente qué debe hacer.

Todos deben contener:

1. Objetivo.
2. Responsabilidades.
3. Alcance.
4. Funcionalidades.
5. Archivos y directorios asignados.
6. Escenas que debe crear.
7. Scripts que debe desarrollar.
8. Clases y responsabilidades.
9. Métodos y señales necesarias.
10. Dependencias con otros integrantes.
11. Orden recomendado de implementación.
12. Pruebas que debe realizar.
13. Criterios de aceptación.
14. Entregables.
15. Procedimiento de Pull Request.

### INTEGRANTE 1: TABLERO Y CASILLAS

Responsable de:

- Tablero 8 × 8.
- Casillas.
- Coordenadas.
- Ocupación.
- Selección.
- Resaltado de movimientos.
- Actualización de posiciones.
- Integración visual con los biomas.

Debe coordinar con el integrante 2 para consultar movimientos legales y con el integrante 4 para la representación visual.

### INTEGRANTE 2: PIEZAS Y REGLAS

Responsable del sistema completo de ajedrez.

Debe desarrollar las seis piezas y las reglas tradicionales.

Debe contemplar:

- Representación de piezas.
- Movimientos.
- Capturas.
- Validación.
- Jaque.
- Jaque mate.
- Ahogado.
- Enroque.
- Captura al paso.
- Promoción.
- Tablas.

Debe coordinar con el tablero y el gestor de turnos.

Este módulo no debe depender de la simulación ambiental para determinar si un movimiento es legal.

### INTEGRANTE 3: MOTOR DE SIMULACIÓN

Responsable de los modelos de simulación.

Debe desarrollar:

- Generador pseudoaleatorio.
- Monte Carlo.
- Balance hídrico.
- M/M/1.
- Caminata aleatoria.
- ABM.

Debe documentar cada algoritmo, sus entradas y salidas, las unidades y los parámetros.

Debe proporcionar interfaces que puedan consumir el gestor del juego y la interfaz.

### INTEGRANTE 4: BIOMAS E INTERFAZ

Responsable de:

- Representación visual de los tres niveles.
- Escenarios.
- HUD.
- Indicadores.
- Información ambiental.
- Información del vivero.
- Pantallas de victoria y derrota.
- Recursos visuales y adaptación de la interfaz.

Debe definir cómo recibe y representa los resultados de la simulación.

### INTEGRANTE 5: INTEGRACIÓN Y PROGRESIÓN

Responsable de:

- Escena principal.
- GameManager.
- TurnManager.
- LevelManager.
- VictoryManager.
- Coordinación de módulos.
- Progresión entre niveles.
- Integración.
- Pruebas de sistema.

Debe establecer los contratos de integración y verificar que los módulos funcionen conjuntamente.

## 7. QUINTA FASE: GIT Y TRABAJO COLABORATIVO

Conserva la estrategia existente:

- main: versión estable.
- develop: integración.
- feature/*: desarrollo por funcionalidades.
- docs/*: documentación.

Documenta:

- Clonación.
- Actualización de develop.
- Creación de ramas.
- Commits.
- Push.
- Pull Requests.
- Revisión.
- Resolución de conflictos.
- Sincronización de ramas.

Incluye comandos Git reales y ejemplos.

No cambies ni elimines las ramas existentes.

No modifiques el historial de Git.

## 8. REQUISITOS DE CALIDAD DOCUMENTAL

Todos los documentos deben:

- Estar escritos en español técnico claro.
- Utilizar Markdown.
- Tener títulos y subtítulos coherentes.
- Incluir tablas cuando aporten claridad.
- Incluir diagramas Mermaid cuando sean útiles.
- Tener enlaces relativos entre documentos.
- Mantener terminología consistente.
- Evitar repeticiones.
- Evitar instrucciones contradictorias.
- Ser suficientemente detallados para orientar la implementación.

No generes documentos con títulos y listas vacías.

No rellenes páginas con texto genérico.

Cada sección debe aportar información útil para el desarrollo real.

## 9. RESTRICCIONES IMPORTANTES

- No borres código existente.
- No sobrescribas escenas ni scripts.
- No cambies project.godot.
- No cambies la configuración del motor.
- No alteres ramas.
- No realices merge.
- No ejecutes reset ni rebase.
- No hagas commits ni push automáticamente.
- No inventes parámetros matemáticos.
- No inventes reglas específicas de los niveles.
- No marques funcionalidades como implementadas si no existen en el código.

El objetivo de esta tarea es documentar y organizar, no programar el videojuego todavía.

Si encuentras inconsistencias, documéntalas y propone cómo resolverlas.

## 10. VERIFICACIÓN FINAL

Cuando termines:

1. Presenta el árbol documental final.
2. Enumera los archivos creados.
3. Enumera los archivos actualizados.
4. Resume las decisiones importantes.
5. Indica las inconsistencias encontradas.
6. Indica los aspectos pendientes de aprobación.
7. Verifica que todos los enlaces internos funcionen.
8. Verifica que no se hayan modificado archivos de código.
9. Verifica el estado de Git.
10. Recomienda el siguiente paso de desarrollo.

Trabaja directamente sobre la rama actual:

`docs/organizacion-version-extendida`

No cambies de rama.

**Resultado esperado:** una documentación técnica profesional, coherente, completa y lista para que los cinco integrantes comiencen a desarrollar la versión extendida de Ajedrez Salvaje.