"""
daza_tocarruncho_figueredo_useche_sanchez_modelo5_dinamica.py
Modelo 5: Dinámica de Sistemas (Reserva Hídrica del Páramo)
ExpoSimu 2026 - Universidad Pedagógica y Tecnológica de Colombia (UPTC)
Integrantes: Daza, Tocarruncho, Figueredo, Useche, Sanchez
"""

import os
import datetime
import getpass
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "graficas")
os.makedirs(OUTPUT_DIR, exist_ok=True)


class WaterSystemSimulation:
    def __init__(self, dt=1.0):
        self.initial_water = 100.0
        self.max_water = 100.0
        self.dt = dt
        self.plant_condensation = 0.2
        self.base_evaporation = 1.0
        self.frost_factor = 3.0
        self.consumption_per_animal = 0.6 / 7.0

    def simulate(self, rounds=10, plants=8, animals=7, climate="Estable"):
        water = self.initial_water
        history = [water]

        for _ in range(rounds):
            f_in = self.plant_condensation * plants
            f_evap = self.base_evaporation * (self.frost_factor if climate == "Helada" else 1.0)
            f_cons = self.consumption_per_animal * animals
            f_out = f_evap + f_cons

            net_rate = f_in - f_out
            water = np.clip(water + self.dt * net_rate, 0.0, self.max_water)
            history.append(water)

        return water, history, net_rate


def main():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    user = getpass.getuser()

    print("=" * 80)
    print("UPTC - SIMULACIÓN DE COMPUTADORES - EXPOSIMU 2026")
    print("MODELO 5: DINÁMICA DE SISTEMAS (RESERVA HÍDRICA DEL PÁRAMO)")
    print(f"Timestamp: {timestamp} | Usuario: {user}")
    print("Método de Integración Numérica: Euler con paso temporal dt = 1.0 (1 ronda)")
    print("=" * 80)

    # 3 Configuraciones obligatorias de parámetros a 10 rondas
    configs = [
        {
            "id": 1,
            "desc": "Equilibrio (8 frailejones, Estable)",
            "plants": 8, "animals": 7, "climate": "Estable",
            "theo_final": 100.0,
            "rate_theo": 0.0
        },
        {
            "id": 2,
            "desc": "Helada Continua (8 frailejones, Helada)",
            "plants": 8, "animals": 7, "climate": "Helada",
            "theo_final": 80.0,  # 100 - 10 * 2.0 = 80.0
            "rate_theo": -2.0
        },
        {
            "id": 3,
            "desc": "Deforestación Severa (4 frailejones, Estable)",
            "plants": 4, "animals": 7, "climate": "Estable",
            "theo_final": 92.0,  # 100 - 10 * 0.8 = 92.0
            "rate_theo": -0.8
        }
    ]

    print("\nTABLA DE VALIDACIÓN EXPERIMENTAL (3 CONFIGURACIONES A 10 RONDAS):")
    print(f"{'Config':<8} | {'Escenario / Parámetros':<36} | {'dA/dt Teo':<10} | {'Agua Teo (%)':<14} | {'Agua Sim (%)':<14} | {'Dif (%)':<8}")
    print("-" * 100)

    sim = WaterSystemSimulation(dt=1.0)
    trajectories = []
    labels = []

    for cfg in configs:
        sim_final, hist, sim_rate = sim.simulate(rounds=10, plants=cfg["plants"], animals=cfg["animals"], climate=cfg["climate"])
        theo_final = cfg["theo_final"]
        dif_pct = abs(sim_final - theo_final) / theo_final * 100.0

        trajectories.append(hist)
        labels.append(cfg["desc"])

        print(f"Config {cfg['id']:<1} | {cfg['desc']:<36} | {cfg['rate_theo']:<10.2f} | {theo_final:<14.2f} | {sim_final:<14.2f} | {dif_pct:<8.2f}%")

    # Gráfico de Validación
    fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
    rounds_x = np.arange(11)

    colors = ['#27ae60', '#8e44ad', '#d35400']
    styles = ['-', '--', '-.']

    for i, hist in enumerate(trajectories):
        ax.plot(rounds_x, hist, label=f"Config {i+1}: {labels[i]}", color=colors[i], linestyle=styles[i], linewidth=2.5)

    ax.axhline(30.0, color='#e74c3c', linestyle=':', linewidth=1.5, label="Umbral Crítico Vivero (30%)")
    ax.set_title("Validación: Trayectorias del Nivel de Agua $A(t)$ según Configuración", fontsize=12, fontweight='semibold')
    ax.set_xlabel("Ronda de Simulación ($t$)", fontsize=10)
    ax.set_ylabel("Nivel de Reserva Hídrica (%)", fontsize=10)
    ax.set_xlim(0, 10)
    ax.set_ylim(70, 105)
    ax.grid(True, alpha=0.3)
    ax.legend(loc='lower left', frameon=True)

    plt.tight_layout()
    fig_path = os.path.join(OUTPUT_DIR, "daza_tocarruncho_figueredo_useche_sanchez_modelo5_dinamica.png")
    plt.savefig(fig_path, dpi=300)
    plt.close()
    print(f"\n[OK] Gráfica de validación guardada en: {fig_path}")

    # Respuestas al Análisis de Sensibilidad (Página 8 de la Guía)
    print("\nANÁLISIS DE SENSIBILIDAD:")
    print("1. ¿Qué parámetro tiene mayor impacto en los resultados?")
    print("   El factor de evaporación por helada (multiplicador x3) y el número de frailejones vivos.")
    print("   La helada provoca una tasa de pérdida neta de -2.0%/turno, superando por más del doble al déficit")
    print("   provocado por perder la mitad de los frailejones (-0.8%/turno).")
    print("2. ¿Los resultados coinciden con la teoría? Si hay discrepancias, explicar posibles causas:")
    print("   Coinciden con 0.00% de error con la integración analítica continua, ya que las tasas en cada")
    print("   régimen son constantes por tramos y el paso de Euler dt=1 ronda es exacto para flujos lineales.")
    print("3. Identificar una limitación del modelo en su forma actual:")
    print("   El modelo asume que el agua se distribuye homogéneamente en todo el páramo (modelo cero-dimensional);")
    print("   no simula gradientes espaciales de humedad entre las distintas casillas del tablero.")
    print("=" * 80)


if __name__ == "__main__":
    main()
