# Reglas del juego

Ajedrez Salvaje es una partida de ajedrez FIDE completo **para dos jugadores
en el mismo equipo**. Cada jugador cuida además su propio ecosistema: si su
reserva de agua se agota, pierde. Una sola partida recorre tres niveles que
endurecen el ambiente.

## Piezas

| Pieza | Especie | Movimiento |
|---|---|---|
| Peón | Frailejón | Avanza una casilla, dos desde su salida; captura en diagonal |
| Caballo | Venado de cola blanca | Salta en forma de L |
| Alfil | Cóndor andino | Diagonal sin saltar |
| Torre | Oso de anteojos | Ortogonal sin saltar |
| Dama | Danta de montaña | Alfil + torre |
| Rey | Frailejón Gran Abuelo | Una casilla en cualquier dirección |

Se aplican jaque, jaque mate, ahogado, enroque, captura al paso y promoción.
Las tablas por 50 jugadas, triple repetición y material insuficiente no están
implementadas; por eso existe una ronda final (ver Victoria).

## Turnos y rondas

Una **ronda** es: fase ambiental, luego mueve el jugador 1 y luego el
jugador 2. Al cambiar de turno el tablero **gira 180°** para que cada jugador
vea desde su lado.

Fase ambiental, en este orden:

1. **Clima** (Monte Carlo): un solo evento para los dos jugadores.
2. **Agua** (dinámica de sistemas): se actualiza la reserva de cada jugador.
3. **Vivero** (cola M/M/1): el vivero de cada jugador avanza si su agua supera
   el 30 %.
4. **Cazador** (agente): da un paso hacia la pieza más cercana.
5. **Retroexcavadora** (caminata aleatoria): solo desde el nivel 3.

## Ecosistema de cada jugador

- **Agua.** Cada jugador empieza con 100 %. Sus frailejones vivos condensan
  agua y la lluvia la recarga; la evaporación, el consumo de sus animales y
  las catástrofes la gastan. Perder peones baja la condensación, así que
  capturar los frailejones del rival ataca su agua.
- **Vivero.** Un peón capturado o destruido entra a la cola del vivero de su
  dueño. Al terminar su germinación rebrota en la primera casilla libre de su
  fila de origen (fila 2 para el jugador 1 y fila 7 para el jugador 2).

## Desestabilizadores

- **Cazador furtivo.** Neutral, empieza en d4. Cada ronda avanza una casilla
  hacia la pieza más cercana, de cualquier bando, y destruye lo que pise. No
  se puede capturar y bloquea el paso.
- **Retroexcavadora.** Aparece al iniciar el nivel 3 en una casilla libre al
  azar. Se mueve con caminata aleatoria, destruye lo que pise y **tala la
  casilla que deja**: queda bloqueada para el resto de la partida.

Si un desestabilizador destruye un rey, gana el otro jugador.

## Niveles

| Nivel | Rondas | Qué cambia |
|---|---|---|
| 1 | 1 a 10 | Cazador y clima normal |
| 2 | 11 a 20 | Clima severo: más heladas y catástrofes |
| 3 | 21 en adelante | Aparece la retroexcavadora |

## Victoria

Se revisa en este orden:

1. **Ajedrez:** jaque mate o rey destruido por un desestabilizador; el ahogado
   es tablas.
2. **Colapso hídrico:** si el agua de un jugador llega a 0, gana el otro. Si
   ambos llegan a 0 en la misma ronda, tablas.
3. **Ronda final (30):** gana quien tenga más agua; si empatan, más material
   (peón 1, caballo y alfil 3, torre 5, dama 9); si también empatan, tablas.
