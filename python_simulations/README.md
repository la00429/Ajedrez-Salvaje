# Módulos de Simulación y Calibración en Python

Este directorio contiene la implementación en **Python 3.12** de los 5 modelos estocásticos y matemáticos que gobiernan el videojuego **Ajedrez Salvaje** (ExpoSimu 2026), desarrollada para validar empíricamente, calibrar y generar las figuras estadísticas de alta resolución (300 DPI) para el informe final de Simulación de Computadores.

Nomenclatura oficial UPTC: `daza_tocarruncho_figueredo_useche_sanchez_modelo[1-5].py`

---

## 1. Estructura de Scripts

| Script | Modelo Matemático | Métricas y Pruebas Evaluadas | Gráfica Generada |
|---|---|---|---|
| `01_rng_lehmer.py` | Generadores Pseudoaleatorios (LCG Knuth y Lehmer MINSTD) | Teorema de Hull-Dobell (período $2^{32}$), Prueba de bondad de ajuste $\chi^2$ de uniformidad, gráficos de dispersión 2D (*lag plot*), pruebas de media ($Z$) y varianza ($\chi^2$). | `graficas/01_rng_calibracion.png` |
| `daza_tocarruncho_figueredo_useche_sanchez_modelo1_caminatas.py` | Modelo 1: Caminata Aleatoria 2D (Retroexcavadora) | Difusión espacial ortogonal con política de rebote/redraw, Desplazamiento Cuadrático Medio $\langle R^2(N) \rangle$, 3 configuraciones de pasos ($N=10, 20, 30$) calibradas teórica vs. empíricamente, 3 preguntas de sensibilidad. | `graficas/daza_tocarruncho_figueredo_useche_sanchez_modelo1_caminatas.png` |
| `daza_tocarruncho_figueredo_useche_sanchez_modelo2_colas.py` | Modelo 2: Teoría de Colas (Vivero $M/M/1$) | Fórmulas analíticas de estado estable ($\rho, L_q, W_q$), simulación de eventos discretos a 10,000 rondas, 3 configuraciones de intensidad de tráfico ($\lambda=0.20, 0.35, 0.45$, $\mu=0.5$), capacidad buffer $K=16$, 3 preguntas de sensibilidad. | `graficas/daza_tocarruncho_figueredo_useche_sanchez_modelo2_colas.png` |
| `daza_tocarruncho_figueredo_useche_sanchez_modelo3_montecarlo.py` | Modelo 3: Simulación Monte Carlo (Clima) | Transformada inversa estocástica, 3 escenarios climáticos (Normal, Severo, Crisis Extrema) a 10,000 réplicas cada uno, intervalos de confianza al 95%, 3 preguntas de sensibilidad. | `graficas/daza_tocarruncho_figueredo_useche_sanchez_modelo3_montecarlo.png` |
| `daza_tocarruncho_figueredo_useche_sanchez_modelo4_agentes.py` | Modelo 4: Sistemas Basados en Agentes (Cazador Voraz) | Heurística voraz orientada por distancia Manhattan $d_M$, 3 configuraciones de distancia inicial ($d_M=2, 3, 6$), comparación teórica vs. simulada de pasos de captura, 3 preguntas de sensibilidad. | `graficas/daza_tocarruncho_figueredo_useche_sanchez_modelo4_agentes.png` |
| `daza_tocarruncho_figueredo_useche_sanchez_modelo5_dinamica.py` | Modelo 5: Dinámica de Sistemas (Nivel Freático) | Ecuación diferencial $dA/dt = F_{in} - F_{out}$, integración numérica por método de Euler ($\Delta t = 1$), 3 configuraciones (Equilibrio, Helada, Deforestación), 3 preguntas de sensibilidad. | `graficas/daza_tocarruncho_figueredo_useche_sanchez_modelo5_dinamica.png` |
| `runner.py` | Orquestador General | Ejecuta los 6 módulos secuencialmente y valida la calibración y generación de todas las figuras. | — |

---

## 2. Requisitos y Ejecución

Se requiere Python 3.10+ con `numpy`, `scipy` y `matplotlib`.

### Ejecutar todas las simulaciones:
```bash
python python_simulations/runner.py
```

### Ejecutar un módulo individual:
```bash
python python_simulations/01_rng_lehmer.py
python python_simulations/daza_tocarruncho_figueredo_useche_sanchez_modelo1_caminatas.py
python python_simulations/daza_tocarruncho_figueredo_useche_sanchez_modelo2_colas.py
python python_simulations/daza_tocarruncho_figueredo_useche_sanchez_modelo3_montecarlo.py
python python_simulations/daza_tocarruncho_figueredo_useche_sanchez_modelo4_agentes.py
python python_simulations/daza_tocarruncho_figueredo_useche_sanchez_modelo5_dinamica.py
```

Todas las figuras generadas se guardan automáticamente en formato PNG de alta resolución (300 DPI) en la carpeta `python_simulations/graficas/`.
