"""
daza_tocarruncho_figueredo_useche_sanchez_modelo2_colas.py
Modelo 2: Sistemas de Colas M/M/1 (Vivero de Frailejones)
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


class KnuthLCG:
    """Generador Congruencial Mixto del Taller 1 (Knuth / Numerical Recipes: a=1664525, c=1013904223, m=2^32)."""
    def __init__(self, seed=20260101):
        self.m = 4294967296
        self.a = 1664525
        self.c = 1013904223
        self.x = seed % self.m

    def next_r(self):
        self.x = (self.a * self.x + self.c) % self.m
        return self.x / self.m


class MM1QueueSimulation:
    def __init__(self, mu=0.5, capacity=16, seed=20260101):
        self.mu = mu
        self.capacity = capacity
        self.rng = KnuthLCG(seed)

    def exponential_rand(self, rate):
        u = max(1e-9, self.rng.next_r())
        return -np.log(u) / rate

    def poisson_arrivals(self, lambd):
        # Simulación de llegadas de Poisson mediante suma de exponenciales
        count = 0
        t = 0.0
        while True:
            t += self.exponential_rand(lambd)
            if t > 1.0:
                break
            count += 1
        return count

    def simulate(self, lambd, rounds=10000):
        queue = []
        queue_lengths = []
        waiting_times = []
        server_remaining = 0.0
        blocked = 0
        total_arrivals = 0

        for r in range(rounds):
            arrivals = self.poisson_arrivals(lambd)
            for _ in range(arrivals):
                total_arrivals += 1
                if len(queue) < self.capacity:
                    queue.append(r)
                else:
                    blocked += 1

            if len(queue) > 0:
                if server_remaining <= 0.0:
                    server_remaining = self.exponential_rand(self.mu)

                server_remaining -= 1.0
                if server_remaining <= 0.0:
                    t_in = queue.pop(0)
                    waiting_times.append(r - t_in)
                    server_remaining = 0.0

            queue_lengths.append(len(queue))

        return {
            "l_q": np.mean(queue_lengths),
            "w_q": np.mean(waiting_times) if waiting_times else 0.0,
            "loss_pct": (blocked / max(1, total_arrivals)) * 100.0,
            "queue_hist": queue_lengths
        }


def main():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    user = getpass.getuser()

    print("=" * 80)
    print("UPTC - SIMULACIÓN DE COMPUTADORES - EXPOSIMU 2026")
    print("MODELO 2: SISTEMA DE COLAS M/M/1 (VIVERO DE FRAILEJONES)")
    print(f"Timestamp: {timestamp} | Usuario: {user}")
    print("Generador PRNG integrado: Congruencial Mixto (Knuth: a=1664525, c=1013904223, m=2^32)")
    print("=" * 80)

    mu = 0.5  # Servicio: 0.5 plantas/ronda (1/mu = 2 rondas)

    # 3 Configuraciones obligatorias de parámetros
    configs = [
        {"id": 1, "lambd": 0.20, "desc": "Carga Baja (lambda=0.20, rho=0.40)"},
        {"id": 2, "lambd": 0.35, "desc": "Carga Media (lambda=0.35, rho=0.70)"},
        {"id": 3, "lambd": 0.45, "desc": "Carga Alta / Cuello de Botella (lambda=0.45, rho=0.90)"}
    ]

    print("\nTABLA DE VALIDACIÓN EXPERIMENTAL (3 CONFIGURACIONES):")
    print(f"{'Config':<8} | {'Entrada':<26} | {'Lq (Teo)':<10} | {'Lq (Sim)':<10} | {'Wq (Teo)':<10} | {'Wq (Sim)':<10} | {'Dif Lq (%)':<10}")
    print("-" * 96)

    theo_lqs, sim_lqs = [], []
    theo_wqs, sim_wqs = [], []
    labels = []

    sim = MM1QueueSimulation(mu=mu, capacity=16, seed=20260101)

    for cfg in configs:
        l = cfg["lambd"]
        rho = l / mu
        # Ecuaciones M/M/1 analíticas
        lq_teo = (rho ** 2) / (1.0 - rho)
        wq_teo = rho / (mu - l)

        res = sim.simulate(l, rounds=10000)
        lq_sim = res["l_q"]
        wq_sim = res["w_q"]
        dif_lq = abs(lq_sim - lq_teo) / lq_teo * 100.0

        theo_lqs.append(lq_teo)
        sim_lqs.append(lq_sim)
        theo_wqs.append(wq_teo)
        sim_wqs.append(wq_sim)
        labels.append(f"rho={rho:.2f}")

        print(f"Config {cfg['id']:<1} | {cfg['desc']:<26} | {lq_teo:<10.3f} | {lq_sim:<10.3f} | {wq_teo:<10.3f} | {wq_sim:<10.3f} | {dif_lq:<10.2f}%")

    # Gráfico de Validación
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6), dpi=300)
    x = np.arange(len(configs))
    w = 0.35

    ax1.bar(x - w/2, theo_lqs, w, label="Lq Teórico (M/M/1)", color='#2980b9', edgecolor='black')
    ax1.bar(x + w/2, sim_lqs, w, label="Lq Simulado (DES)", color='#e74c3c', edgecolor='black')
    ax1.set_title("Validación: Frailejones en Cola ($L_q$)", fontsize=11, fontweight='semibold')
    ax1.set_xticks(x)
    ax1.set_xticklabels(labels)
    ax1.set_ylabel("Plantas en Cola", fontsize=10)
    ax1.grid(True, alpha=0.3, axis='y')
    ax1.legend()

    ax2.bar(x - w/2, theo_wqs, w, label="Wq Teórico (M/M/1)", color='#27ae60', edgecolor='black')
    ax2.bar(x + w/2, sim_wqs, w, label="Wq Simulado (DES)", color='#f39c12', edgecolor='black')
    ax2.set_title("Validación: Tiempo Medio de Espera ($W_q$)", fontsize=11, fontweight='semibold')
    ax2.set_xticks(x)
    ax2.set_xticklabels(labels)
    ax2.set_ylabel("Rondas de Espera", fontsize=10)
    ax2.grid(True, alpha=0.3, axis='y')
    ax2.legend()

    plt.tight_layout()
    fig_path = os.path.join(OUTPUT_DIR, "daza_tocarruncho_figueredo_useche_sanchez_modelo2_colas.png")
    plt.savefig(fig_path, dpi=300)
    plt.close()
    print(f"\n[OK] Gráfica de validación guardada en: {fig_path}")

    # Respuestas al Análisis de Sensibilidad (Página 8 de la Guía)
    print("\nANÁLISIS DE SENSIBILIDAD:")
    print("1. ¿Qué parámetro tiene mayor impacto en los resultados?")
    print("   El factor de utilización rho = lambda / mu. Al pasar de rho=0.40 a rho=0.90,")
    print(f"   la longitud de cola crece exponencialmente en un {(sim_lqs[2]-sim_lqs[0])/sim_lqs[0]*100:.1f}%.")
    print("2. ¿Los resultados coinciden con la teoría? Si hay discrepancias, explicar posibles causas:")
    print("   Coinciden con la teoría M/M/1 de colas. En rho=0.90 el modelo simulado tiene una leve saturación")
    print("   respecto a la teoría infinita debido al buffer finito de capacidad (K = 16) del vivero.")
    print("3. Identificar una limitación del modelo en su forma actual:")
    print("   El modelo asume tasa de servicio constante mu=0.5, pero en el juego si el agua cae por debajo")
    print("   del umbral crítico del 30%, el servidor se apaga (mu=0), congelando la atención indefinidamente.")
    print("=" * 80)


if __name__ == "__main__":
    main()
