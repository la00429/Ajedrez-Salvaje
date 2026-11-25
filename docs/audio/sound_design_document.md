# SOUND DESIGN DOCUMENT (SDD)
## Ajedrez Salvaje: Biomas de Colombia
**Versión:** 1.0 – Propuesta inicial  
**Proyecto:** ExpoSimu 2026  
**Motor:** Godot 4  
**Lenguaje de implementación:** GDScript  
**Enfoque sonoro:** Híbrido (naturalista, cinematográfico y adaptativo)

---

# 1. Introducción

El diseño sonoro de *Ajedrez Salvaje: Biomas de Colombia* tiene como propósito construir una experiencia auditiva inmersiva que represente la identidad ecológica de los biomas del juego y comunique los cambios que ocurren durante la simulación.

El sonido no se limitará a reproducir música ambiental de manera continua. Se diseñará como un sistema dinámico que responda a las condiciones ambientales, los eventos de juego, las decisiones de los jugadores y los resultados de los modelos de simulación.

Se combinarán tres elementos principales:

- **Paisajes sonoros naturalistas:** grabaciones de fauna, flora, agua, viento, lluvia y otros fenómenos ambientales.
- **Composición musical ambiental:** melodías, armonías, texturas y motivos originales que representen la identidad emocional de cada ecosistema.
- **Diseño sonoro procedural:** procesamiento y transformación de sonidos mediante parámetros que cambian según el estado del juego.

La intención es que el jugador pueda percibir auditivamente cuándo un ecosistema se encuentra en equilibrio, cuándo está siendo perturbado y cuándo se aproxima a un estado de colapso.

# 2. Objetivos

## 2.1. Objetivo general

Diseñar e implementar un sistema de audio inmersivo y adaptativo que represente los ecosistemas colombianos de Ajedrez Salvaje y responda dinámicamente a las variables ambientales, los eventos y los estados de la simulación.

## 2.2. Objetivos específicos

1. Construir una identidad acústica diferenciada para los tres niveles del juego.
2. Incorporar grabaciones reales de ambientes naturales y sonidos de fauna representativa.
3. Crear composiciones musicales originales mediante principios de teoría musical y producción digital.
4. Diseñar efectos sonoros para las interacciones de las piezas, el vivero, el clima y los eventos ambientales.
5. Vincular los parámetros del sistema de audio con los resultados de los cinco modelos de simulación.
6. Implementar un administrador centralizado de audio en Godot 4.
7. Garantizar transiciones sonoras suaves, coherencia ambiental y rendimiento adecuado.

# 3. Dirección artística y concepto sonoro

## 3.1. Identidad general

La dirección artística será híbrida.

El componente naturalista tendrá prioridad en la representación del ambiente: los sonidos de fauna, lluvia, agua y viento deberán conservar características reconocibles y creíbles.

El componente musical acompañará la experiencia mediante texturas ambientales, armonías, motivos melódicos y cambios de intensidad.

El componente procedural permitirá modificar el comportamiento del sonido según las condiciones del ecosistema.

No se busca convertir cada animal en un instrumento musical ni musicalizar todos los efectos. La composición y el ambiente natural deben complementarse sin competir entre sí.

## 3.2. Principios de diseño

- **Autenticidad:** priorizar sonidos naturales compatibles con el ecosistema representado.
- **Coherencia:** evitar sonidos que contradigan las condiciones ambientales.
- **Adaptabilidad:** modificar el paisaje sonoro cuando cambien las variables de simulación.
- **Continuidad:** evitar cortes abruptos y repeticiones perceptibles.
- **Jerarquía:** distinguir ambiente, música, eventos y alertas.
- **Moderación:** el sonido debe informar sin saturar ni distraer al jugador.
- **Identidad colombiana:** representar los ambientes mediante referencias ecológicas pertinentes al territorio colombiano.

# 4. Identidad sonora de los niveles

## 4.1. Nivel 1: Páramo en Alerta — Reserva de Sumapaz

**Concepto:** aislamiento, frío, viento, humedad y equilibrio ecológico.

El paisaje sonoro debe transmitir la amplitud del páramo y su fragilidad ambiental.

### Capas ambientales

- Viento frío de montaña.
- Sonidos de vegetación y frailejones movidos por el viento.
- Aves altoandinas y fauna local documentada.
- Gotas de agua, humedad y lluvia ligera.
- Texturas ambientales de baja intensidad.

### Identidad musical

- Texturas sostenidas y espaciales.
- Melodías discretas.
- Armonías abiertas y poco densas.
- Instrumentos acústicos o sintetizadores suaves.
- Ritmos lentos o ausencia de percusión marcada.

### Adaptación

En condiciones estables, el ambiente será amplio y tranquilo.

Durante las heladas, aumentará la presencia del viento frío y disminuirá la actividad sonora de la fauna.

Cuando disminuya el agua, la composición podrá introducir tensiones armónicas graduales.

La aproximación del cazador furtivo podrá activar señales discretas de perturbación.

## 4.2. Nivel 2: Frente de Deforestación — Selva Amazónica

**Concepto:** abundancia biológica, humedad, densidad vegetal y amenaza antrópica.

El paisaje sonoro debe transmitir una selva viva, compleja y llena de actividad.

### Capas ambientales

- Coros de insectos tropicales.
- Aves y anfibios representativos.
- Lluvia tropical.
- Corrientes de agua.
- Movimiento de vegetación.
- Sonidos ambientales de baja frecuencia.
- Maquinaria minera y perturbación humana.

### Identidad musical

- Texturas orgánicas.
- Percusiones sutiles.
- Sonidos resonantes y acuáticos.
- Motivos musicales cortos.
- Armonías que transmitan profundidad y actividad.

### Adaptación

Cuando el ecosistema se encuentre saludable, habrá mayor riqueza de capas ambientales.

Durante las lluvias, se incorporará precipitación y actividad acuática.

Cuando se presente una catástrofe, se activarán efectos específicos del evento.

La maquinaria minera tendrá una identidad sonora contrastante frente a los sonidos naturales.

La pérdida de agua y vegetación deberá reflejarse progresivamente en el paisaje sonoro.

## 4.3. Nivel 3: Colapso Antrópico — Santuario Mixto en Crisis

**Concepto:** desequilibrio, fragmentación ecológica y tensión.

Este nivel combinará elementos sonoros del páramo y de la selva, pero no deberá percibirse simplemente como una mezcla de los otros dos niveles.

La identidad deberá comunicar un ecosistema sometido a múltiples perturbaciones.

### Capas ambientales

- Elementos sonoros del páramo y la Amazonía.
- Fauna perturbada.
- Sonidos asociados a las especies invasoras definidas para el nivel.
- Eventos de actividad humana.
- Silencios ambientales progresivos.
- Texturas musicales de tensión.

### Identidad musical

- Armonías más inestables.
- Motivos musicales fragmentados.
- Contrastes entre registros graves y agudos.
- Texturas superpuestas.
- Mayor tensión conforme se aproxima el colapso.

### Adaptación

Cuando el ecosistema conserve suficiente agua, se mantendrá parte de su riqueza ambiental.

Cuando se deteriore, algunas capas naturales disminuirán.

Si el agua se aproxima al colapso, la composición podrá perder progresivamente sus elementos armónicos y melódicos.

La victoria deberá recuperar una sensación de resolución y estabilidad. La derrota podrá finalizar con una reducción del paisaje sonoro y una composición de cierre.

# 5. Arquitectura de audio por capas

El sistema se organizará en cinco categorías.

| Categoría | Responsabilidad |
|---|---|
| Ambience | Paisajes sonoros ambientales continuos. |
| Music | Composición musical adaptativa. |
| Fauna | Sonidos de animales y actividad biológica. |
| Events | Interacciones y eventos de juego. |
| Simulation | Fenómenos ambientales y resultados de los modelos. |

## 5.1. Ambience

Gestionará los sonidos continuos del entorno:

- Viento.
- Lluvia.
- Agua.
- Vegetación.
- Ambiente general del bioma.

Los ambientes deberán utilizar grabaciones en bucle con transiciones que eviten interrupciones perceptibles.

## 5.2. Music

Gestionará las composiciones originales.

La música podrá dividirse en capas:

- Capa armónica.
- Capa melódica.
- Textura ambiental.
- Percusión.
- Capa de tensión.

Las capas podrán activarse, desactivarse o modificar su volumen según el estado del juego.

## 5.3. Fauna

Gestionará los sonidos de animales.

Los sonidos deberán tener variaciones de tiempo, volumen y selección para evitar que se repitan de manera mecánica.

La actividad de fauna podrá relacionarse con el estado ecológico, pero no deberá interpretarse como un conteo literal de animales si el modelo no representa esa población.

## 5.4. Events

Contendrá los sonidos asociados a las acciones del jugador:

- Selección de pieza.
- Movimiento.
- Captura.
- Cosecha voluntaria de peones.
- Entrada al vivero.
- Regeneración.
- Regreso de una pieza al tablero.
- Jaque.
- Victoria y derrota.

## 5.5. Simulation

Contendrá los sonidos asociados a los modelos de simulación:

- Variaciones climáticas.
- Heladas.
- Lluvias.
- Catástrofes.
- Movimiento del disruptor.
- Perturbaciones humanas.
- Cambios ecológicos.
- Estado de colapso.

# 6. Música y teoría musical

La composición musical se desarrollará mediante teoría musical aplicada a la identidad de cada bioma.

No se establecerá una tonalidad obligatoria para cada nivel hasta realizar las primeras pruebas de composición.

Se explorarán los siguientes elementos:

| Elemento | Aplicación |
|---|---|
| Escalas | Definir el carácter melódico de cada bioma. |
| Armonía | Representar equilibrio, tensión y resolución. |
| Intervalos | Construir motivos musicales reconocibles. |
| Ritmo | Representar actividad y movimiento. |
| Timbre | Diferenciar las identidades acústicas. |
| Dinámica | Adaptar intensidad y presencia musical. |
| Textura | Combinar sonidos naturales e instrumentos. |

## 6.1. Composición adaptativa

La música se diseñará mediante capas compatibles entre sí.

En lugar de crear una pista completamente diferente para cada posible situación, se producirán segmentos musicales que puedan combinarse.

Por ejemplo:

- Ambiente saludable: armonía principal y textura natural.
- Estrés ambiental: incorporación de una capa de tensión.
- Amenaza: aparición de un motivo musical de alerta.
- Recuperación: transición hacia la armonía principal.
- Colapso: reducción de capas y transformación de la armonía.

Las composiciones deberán mantener compatibilidad tonal, rítmica y de duración para que las transiciones no generen cortes musicales.

# 7. Sistema de audio adaptativo

## 7.1. Variables de entrada

El sistema recibirá información de los módulos de simulación y del administrador del juego.

| Origen | Variable o evento | Respuesta sonora |
|---|---|---|
| Balance hídrico | Nivel de agua A(t) | Modificación de tensión y riqueza ambiental. |
| Monte Carlo | Estado climático | Activación de capas de lluvia, helada o catástrofe. |
| Caminata aleatoria | Posición y colisión del disruptor | Señales sonoras de perturbación. |
| Cola M/M/1 | Llegada y regeneración de piezas | Efectos de vivero y regeneración. |
| ABM | Movimiento y decisiones de fauna rival | Efectos de actividad, alerta o interacción. |
| Administrador de juego | Capturas, movimientos y jaque | Efectos de interacción. |
| Administrador de niveles | Cambio de bioma | Transición entre paisajes sonoros. |

## 7.2. Estados ecológicos

Se propone utilizar tres estados generales de audio:

**Estado saludable**

- Paisaje sonoro completo.
- Mayor riqueza de fauna.
- Música de baja tensión.
- Ambientes naturales predominantes.

**Estado de estrés**

- Disminución gradual de algunas capas ambientales.
- Mayor presencia de texturas graves.
- Música con mayor tensión.
- Eventos de alerta más perceptibles.

**Estado crítico**

- Reducción de actividad ambiental.
- Mayor presencia de sonidos de perturbación.
- Música fragmentada o inestable.
- Posibilidad de silencios ambientales controlados.

Los umbrales de estos estados serán configurables por nivel. No se deben confundir con las condiciones de victoria o derrota: el estado sonoro es una representación audiovisual del ecosistema.

## 7.3. Relación con el balance hídrico

La variable A(t) podrá utilizarse para controlar:

- Intensidad de determinadas capas ambientales.
- Presencia de texturas de agua.
- Nivel de tensión musical.
- Transiciones entre estados ecológicos.

Los umbrales iniciales de audio serán parámetros configurables y deberán probarse. Las condiciones de victoria existentes, como mantener agua por encima del 30 % o del 60 %, conservarán su propia lógica en el administrador del juego.

## 7.4. Reglas de adaptación

1. Las transiciones de volumen deben ser graduales.
2. Los eventos importantes tendrán prioridad sobre los sonidos ambientales.
3. Una misma perturbación no debe generar múltiples reproducciones duplicadas.
4. Los sonidos continuos no deben reiniciarse en cada turno.
5. Los cambios de estado deben evitar variaciones bruscas.
6. Las capas musicales deben conservar compatibilidad.
7. Los sonidos de fauna deberán contar con intervalos y variaciones.
8. La derrota por colapso deberá reflejarse auditivamente sin depender exclusivamente de una alerta.

# 8. Arquitectura de implementación en Godot 4

Se implementó un administrador centralizado denominado `AudioManager`.

Ubicación:

`scripts/audio/audio_manager.gd`

Se registra como Autoload en `project.godot`; no necesita una escena propia.

El administrador será responsable de:

- Cargar y reproducir recursos sonoros.
- Administrar los buses de audio.
- Controlar los ambientes por nivel.
- Recibir eventos de simulación.
- Adaptar volúmenes y capas musicales.
- Evitar reproducciones duplicadas.
- Administrar transiciones y estados.

## 8.1. Buses de audio

Se proponen los siguientes buses:

| Bus | Función |
|---|---|
| Master | Volumen general. |
| Music | Música original. |
| Ambience | Ambientes de bioma, clima y fauna continua. |
| SFX | Eventos de juego, simulación, fauna puntual y maquinaria. |
| UI | Interacciones de la interfaz. |

Los cinco buses están definidos en `audio_bus_layout.tres`; Music, Ambience, SFX y UI envían su salida a Master. Los controles de volumen y mute están disponibles por bus en el menú de pausa.

## 8.2. Comunicación entre módulos

Los módulos del juego no deberán controlar directamente los archivos de audio.

En su lugar, emitirán señales o eventos semánticos que recibirá el administrador.

Ejemplos conceptuales:

- `water_level_changed(value)`
- `weather_changed(weather_type)`
- `disruptor_collision(position)`
- `nursery_regeneration_completed(piece)`
- `piece_captured(piece)`
- `king_threatened()`
- `biome_changed(biome_id)`
- `ecosystem_collapsed()`

El administrador de audio interpretará estos eventos y seleccionará la respuesta correspondiente.

## 8.3. Recursos de Godot

Se utilizarán principalmente:

- `AudioStreamPlayer`: reproducción global de ambientes y música.
- `AudioStreamPlayer2D`: sonidos localizados en el tablero 2D.
- `AudioStreamPlayer3D`: únicamente si se implementa una experiencia espacial 3D.
- `AudioStream`: recursos de audio.
- `AudioEffect`: procesamiento mediante efectos.
- `AudioServer`: administración de buses.

Se recomienda utilizar `AudioStreamInteractive` o un sistema propio de capas cuando resulte conveniente para las transiciones musicales.

# 9. Organización de archivos

La estructura de recursos existente se conserva:

```text
assets/
└── audio/
    ├── ambience/
    │   ├── paramo/
    │   ├── amazonia/
    │   └── santuario/
    ├── fauna/
    │   ├── paramo/
    │   ├── amazonia/
    │   └── santuario/
    ├── weather/
    ├── events/
    ├── simulation/
    ├── music/
    │   ├── paramo/
    │   ├── amazonia/
    │   └── santuario/
    └── ui/
```

El sistema integrado añade:

```text
scripts/
└── audio/
    └── audio_manager.gd
audio_bus_layout.tres
```

El catálogo usa los nombres descriptivos en minúsculas y con guiones bajos. Los recursos integrados están en MP3 y sus rutas se registran en el Autoload.

Ejemplos:

- `paramo_wind_loop.wav`
- `amazon_rain_loop.wav`
- `forest_insects_loop.wav`
- `nursery_regeneration.wav`
- `piece_capture.wav`
- `ecosystem_collapse.wav`
- `paramo_ambient_music.wav`

# 10. Formatos y criterios técnicos

Los archivos maestros de producción podrán mantenerse en WAV.

Para la integración en Godot se evaluarán los formatos según su función:

| Recurso | Formato de trabajo recomendado |
|---|---|
| Grabaciones originales | WAV |
| Ambientes continuos | WAV u OGG |
| Música ambiental | WAV u OGG |
| Efectos cortos | WAV |
| Sonidos de interfaz | WAV |

Se utilizarán frecuencias de muestreo y canales consistentes dentro de cada colección.

Como punto de partida, se recomienda trabajar con WAV a 48 kHz durante la edición y producción.

Los sonidos continuos deberán revisarse para evitar clics, cortes o diferencias bruscas entre el final y el comienzo del bucle.

También se deberá controlar:

- Volumen máximo.
- Picos y saturación.
- Duración de los archivos.
- Tamaño total de los recursos.
- Compatibilidad con Godot.
- Licencias y atribuciones.

# 11. Fuentes de producción sonora

La producción combinará tres fuentes:

## 11.1. Grabaciones reales

Se buscarán grabaciones de:

- Viento de montaña.
- Lluvia y agua.
- Vegetación.
- Aves altoandinas.
- Fauna amazónica.
- Insectos.
- Anfibios.
- Maquinaria y perturbación humana.

Las grabaciones deberán corresponder, en la medida de lo posible, a especies y ambientes compatibles con los ecosistemas representados.

Fuentes de consulta:

- Freesound.
- BBC Sound Effects.
- Bibliotecas de sonidos naturales con licencias compatibles.
- Grabaciones propias, cuando sea posible.

Cada archivo deberá registrar su procedencia, autor, licencia y modificaciones realizadas.

## 11.2. Composición original

Se producirán melodías y texturas musicales mediante:

- Instrumentos virtuales.
- Sintetizadores.
- Percusión.
- Grabaciones procesadas.
- Armonías y escalas seleccionadas para cada bioma.

## 11.3. Síntesis y procesamiento

Se podrán generar sonidos originales mediante:

- Síntesis sustractiva.
- Síntesis granular.
- Osciladores y ruido filtrado.
- Reverberación.
- Ecualización.
- Modulación.
- Automatización de parámetros.

Estas técnicas permitirán construir sonidos que complementen las grabaciones reales sin reemplazar innecesariamente la identidad de los ambientes naturales.

# 12. Criterios de calidad

El sistema se considerará funcional cuando cumpla los siguientes criterios:

1. Cada nivel tendrá una identidad sonora reconocible.
2. Los ambientes podrán reproducirse continuamente sin cortes perceptibles.
3. Los eventos del juego activarán los efectos correspondientes.
4. Las variables ambientales modificarán el sonido de manera coherente.
5. Las transiciones serán graduales.
6. Los sonidos no se duplicarán innecesariamente.
7. La música no interferirá con la comprensión de los eventos importantes.
8. El sistema permitirá modificar volúmenes de manera independiente.
9. Los recursos tendrán licencias compatibles con el proyecto.
10. El rendimiento del juego se mantendrá estable durante la reproducción.

# 13. Alcance y limitaciones

El diseño sonoro inicial estará enfocado en una experiencia 2D con audio ambiental adaptativo.

No se contempla inicialmente:

- Simulación acústica física de los ecosistemas.
- Posicionamiento espacial 3D completo.
- Reconstrucción científica de todos los sonidos de las especies.
- Generación de audio mediante inteligencia artificial en tiempo real.
- Composición musical completamente procedural.

La adaptación se realizará mediante selección, mezcla, procesamiento y control de recursos previamente producidos.

La fidelidad ecológica dependerá de la disponibilidad de grabaciones confiables y de la validación de las especies y ambientes representados.

# 14. Resultado esperado

El resultado será un sistema sonoro que permita experimentar Ajedrez Salvaje no solo visualmente, sino también a través de los cambios auditivos del ecosistema.

El jugador deberá poder reconocer diferencias entre el páramo, la Amazonía y el santuario mixto, y percibir cómo las acciones, las perturbaciones y las condiciones ambientales modifican progresivamente el paisaje sonoro.

El audio será, por tanto, una extensión de los modelos de simulación y no un elemento independiente de la experiencia de juego.

# 15. Integración implementada

## 15.1. Uso desde GDScript

`AudioManager` es un Autoload global. Los scripts deben invocar sus métodos semánticos, sin cargar los archivos directamente:

```gdscript
AudioManager.set_biome(&"amazonia")
AudioManager.play_event(&"piece_capture")
AudioManager.play_ui(&"confirm")
AudioManager.play_fauna_call(&"amazonia")
AudioManager.play_simulation(&"regeneration")
AudioManager.update_simulation_state(&"amazonia", &"rain", lowest_water_percent, mining_active)
AudioManager.set_bus_volume(&"Music", 0.75)
AudioManager.set_bus_muted(&"SFX", true)
```

`set_biome(biome, play_transition)` selecciona la música y el ambiente del bioma; `play_transition` es opcional y por defecto está desactivado. `update_simulation_state` recibe el clima (`stable`, `rain`, `frost` o `catastrophe`), el porcentaje de agua más bajo de los dos ecosistemas y si la retroexcavadora está activa. Lluvia, helada y catástrofe activan o cambian su capa ambiental; el aviso de poca agua se dispara al cruzar el 30 % y se rearma al superar el 35 %. La fauna continua se activa al alcanzar el 60 % y se apaga bajo el 55 %. Estos umbrales solo controlan el audio; no modifican las reglas ni la simulación.

`stop_music()`, `stop_biome_ambience()`, `stop_simulation_audio()` y `stop_all_audio()` detienen las capas correspondientes. Los cambios de bioma y clima usan fundidos de un segundo. Las capas ambientales y musicales no se reinician si su recurso ya está activo. Los efectos de juego e interfaz tienen grupos de reproducción limitados y una ventana de 350 ms para evitar duplicados.

## 15.2. Recursos y buses

El catálogo `AudioManager.AUDIO_PATHS` registra los 31 MP3 bajo sus rutas actuales en `assets/audio/`. `AudioManager.validate_audio_resources()` devuelve las rutas que Godot no encuentra. Ambientes, clima y fauna continua se enrutan a Ambience; música a Music; eventos, simulación, fauna puntual y maquinaria a SFX; controles a UI.

## 15.3. Integración y verificación

`GameManager` conecta el inicio de partida, movimiento, captura, jaque, resultado, clima, agua, regeneración del vivero, actividad real de la retroexcavadora y ataques del cazador. La pantalla de pausa expone volumen y mute de los cinco buses. El menú principal cambia el audio durante la vista previa del bioma.

Ejecuta la prueba de recursos y buses con:

```text
godot --headless --path . --script res://tests/audio/test_audio_manager.gd
```