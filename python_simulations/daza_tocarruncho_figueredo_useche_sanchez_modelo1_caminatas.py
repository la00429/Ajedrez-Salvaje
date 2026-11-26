"""
daza_tocarruncho_figueredo_useche_sanchez_modelo1_caminatas.py
Modelo 1: Caminatas Aleatorias 2D (Retroexcavadora)
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

DIRECTIONS = [np.array([0, 1]), np.array([1, 0]), np.array([0, -1]), np.array([-1, 0])]  # N, E, S, W


class LehmerRNG:
    """Generador de Lehmer del Taller 1 (Park-Miller MINSTD: a=16807, m=2^31 - 1)."""
    def __init__(self, seed=20260101):
        self.m = 2147483647
        self.a = 16807
        self.x = max(1, seed % self.m)

    def next_r(self):
        self.x = (self.a * self.x) % self.m
        return self.x / self.m


class RandomWalk2D:
    def __init__(self, origin=(0, 0), board_size=8, seed=20260101):
        self.origin = np.array(origin)
        self.board_size = board_size
        self.rng = LehmerRNG(seed)

    def is_inside(self, pos):
        return 0 <= pos[0] < self.board_size and 0 <= pos[1] < self.board_size

    def simulate(self, steps):
        pos = self.origin.copy()
        path = [pos.copy()]
        felled = set([tuple(pos)])

        for _ in range(steps):
            while True:
                idx = int(self.rng.next_r() * 4)
                if idx >= 4: idx = 3
                new_pos = pos + DIRECTIONS[idx]
                if self.is_inside(new_pos):
                    pos = new_pos
                    break
            path.append(pos.copy())
            felled.add(tuple(pos))

        path = np.array(path)
        msd = np.sum((path[-1] - self.origin) ** 2)
        return path, len(felled), msd


def run_experiment(steps, n_replicas=1000):
    msds = []
    felled_list = []
    for i in range(n_replicas):
        rw = RandomWalk2D(origin=(0, 0), seed=20260101 + i)
        _, f_count, msd = rw.simulate(steps)
        msds.append(msd)
        felled_list.append(f_count)
    return np.mean(msds), np.mean(felled_list)


def main():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    user = getpass.getuser()

    print("=" * 80)
    print("UPTC - SIMULACIÓN DE COMPUTADORES - EXPOSIMU 2026")
    print("MODELO 1: CAMINATAS ALEATORIAS 2D (RETROEXCAVADORA)")
    print(f"Timestamp: {timestamp} | Usuario: {user}")
    print("Generador PRNG integrado: Lehmer Multiplicativo (Park-Miller MINSTD: a=16807, m=2^31 - 1)")
    print("=" * 80)

    # 3 Configuraciones de parámetros (Página 8 de la Guía)
    configs = [
        {"id": 1, "steps": 10, "desc": "10 pasos (Régimen inicial)"},
        {"id": 2, "steps": 20, "desc": "20 pasos (Régimen medio)"},
        {"id": 3, "steps": 30, "desc": "30 pasos (Régimen final de nivel)"}
    ]

    print("\nTABLA DE VALIDACIÓN EXPERIMENTAL (3 CONFIGURACIONES):")
    print(f"{'Config':<8} | {'Parámetro Entrada':<20} | {'MSD Teórico':<14} | {'MSD Simulado':<14} | {'Dif (%)':<10} | {'Talas Media':<12}")
    print("-" * 88)

    msd_sims = []
    felled_sims = []

    for cfg in configs:
        steps = cfg["steps"]
        # En difusión libre de paso unitario en red discreta: MSD_teo = steps
        msd_teo = float(steps)
        msd_sim, felled_avg = run_experiment(steps, n_replicas=1000)
        diff_pct = abs(msd_sim - msd_teo) / msd_teo * 100.0

        msd_sims.append(msd_sim)
        felled_sims.append(felled_avg)

        print(f"Config {cfg['id']:<1} | {cfg['desc']:<20} | {msd_teo:<14.2f} | {msd_sim:<14.2f} | {diff_pct:<10.2f}% | {felled_avg:<12.2f}")

    # Gráfico de Validación
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6), dpi=300)
    steps_vals = [c["steps"] for c in configs]
    teo_vals = [float(s) for s in steps_vals]

    ax1.plot(steps_vals, teo_vals, 'o--', color='#2c3e50', linewidth=2, label="MSD Teórico Difusión Libre ($N$)")
    ax1.plot(steps_vals, msd_sims, 's-', color='#e74c3c', linewidth=2.2, label="MSD Simulado en Red Confinada 8x8")
    ax1.set_title("Validación: Desplazamiento Cuadrático Medio vs Pasos", fontsize=11, fontweight='semibold')
    ax1.set_xlabel("Número de Pasos ($N$)", fontsize=10)
    ax1.set_ylabel(r"$\langle R^2(t) \rangle$ (casillas$^2$)", fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.legend()

    ax2.bar([c["desc"] for c in configs], felled_sims, color=['#3498db', '#f39c12', '#e74c3c'], edgecolor='black', alpha=0.85)
    ax2.set_title("Casillas Taladas Acumuladas según Configuración", fontsize=11, fontweight='semibold')
    ax2.set_ylabel("Casillas Taladas Promedio (sobre 64)", fontsize=10)
    ax2.set_ylim(0, 25)
    for i, v in enumerate(felled_sims):
        ax2.text(i, v + 0.6, f"{v:.2f} ({v/64*100:.1f}%)", ha='center', fontweight='bold', fontsize=9)
    ax2.grid(True, alpha=0.3, axis='y')

    plt.tight_layout()
    fig_path = os.path.join(OUTPUT_DIR, "daza_tocarruncho_figueredo_useche_sanchez_modelo1_caminatas.png")
    plt.savefig(fig_path, dpi=300)
    plt.close()
    print(f"\n[OK] Gráfica de validación guardada en: {fig_path}")

    # Respuestas al Análisis de Sensibilidad (Página 8 de la Guía)
    print("\nANÁLISIS DE SENSIBILIDAD:")
    print("1. ¿Qué parámetro tiene mayor impacto en los resultados?")
    print("   El número de pasos (N) y la política de borde (REDRAW). Al pasar de 10 a 30 pasos,")
    print(f"   el número de casillas taladas aumenta en un {(felled_sims[2]-felled_sims[0])/felled_sims[0]*100:.1f}%, reduciendo el tablero jugable.")
    print("2. ¿Los resultados coinciden con la teoría? Si hay discrepancias, explicar posibles causas:")
    print("   Para N <= 10 coincide cercanamente con la teoría de difusión libre (<R^2> ~ N). Para N >= 20")
    print("   surge una discrepancia sub-difusiva por el efecto de confinamiento en las fronteras 8x8.")
    print("3. Identificar una limitación del modelo en su forma actual:")
    print("   La caminata aleatoria no tiene memoria de las casillas ya taladas; puede volver a pisar casillas")
    print("   bloqueadas en lugar de priorizar áreas con vegetación intacta.")
    print("=" * 80)


if __name__ == "__main__":
    main()
