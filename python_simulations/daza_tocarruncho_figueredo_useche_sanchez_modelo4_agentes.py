"""
daza_tocarruncho_figueredo_useche_sanchez_modelo4_agentes.py
Modelo 4: Sistemas Basados en Agentes - ABM (Cazador Furtivo)
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
    """Generador Congruencial Mixto del Taller 1 (Knuth: a=1664525, c=1013904223, m=2^32)."""
    def __init__(self, seed=20260101):
        self.m = 4294967296
        self.a = 1664525
        self.c = 1013904223
        self.x = seed % self.m

    def next_r(self):
        self.x = (self.a * self.x + self.c) % self.m
        return self.x / self.m

    def next_int(self, upper):
        return int(self.next_r() * upper) % upper


class HunterAgentABM:
    def __init__(self, origin=(3, 3), seed=20260101):
        self.origin = np.array(origin)
        self.rng = KnuthLCG(seed)

    def manhattan(self, p1, p2):
        return abs(p1[0] - p2[0]) + abs(p1[1] - p2[1])

    def simulate(self, pieces_coords, max_steps=40):
        pos = self.origin.copy()
        pieces = set(pieces_coords)
        step = 0
        path = [pos.copy()]
        capture_step = None

        while step < max_steps and len(pieces) > 0:
            step += 1
            # 1. Percepción: Distancias Manhattan
            distances = [self.manhattan(pos, p) for p in pieces]
            min_dist = min(distances)
            nearest = [p for p, d in zip(pieces, distances) if d == min_dist]

            # 2. Selección de presa
            target = nearest[self.rng.next_int(len(nearest))]

            # 3. Política de aproximación
            dx = target[0] - pos[0]
            dy = target[1] - pos[1]
            moves = []
            if dx > 0: moves.append(np.array([1, 0]))
            elif dx < 0: moves.append(np.array([-1, 0]))
            if dy > 0: moves.append(np.array([0, 1]))
            elif dy < 0: moves.append(np.array([0, -1]))

            if moves:
                pos = pos + moves[self.rng.next_int(len(moves))]
            path.append(pos.copy())

            # 4. Captura
            if tuple(pos) in pieces:
                capture_step = step
                break

        return capture_step, path


def get_pieces_config(cfg_id):
    if cfg_id == 1:
        # Config 1: Tablero completo (32 piezas, presas a distancia dM = 2)
        pcs = []
        for c in range(8):
            pcs.extend([(c, 0), (c, 1), (c, 6), (c, 7)])
        return pcs, 2.0, "Tablero Completo (32 piezas, dM_min=2)"
    elif cfg_id == 2:
        # Config 2: Medio juego (16 piezas en filas extremas 0 y 7, dM = 3)
        pcs = []
        for c in range(8):
            pcs.extend([(c, 0), (c, 7)])
        return pcs, 3.0, "Medio Juego (16 piezas, dM_min=3)"
    else:
        # Config 3: Final disperso (4 piezas en esquinas (0,0), (7,0), (0,7), (7,7), dM = 6 o 7)
        pcs = [(0, 0), (7, 0), (0, 7), (7, 7)]
        # distancia de (3,3) a (0,0) es |3-0| + |3-0| = 6
        return pcs, 6.0, "Final Disperso (4 esquinas, dM_min=6)"


def main():
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    user = getpass.getuser()

    print("=" * 80)
    print("UPTC - SIMULACIÓN DE COMPUTADORES - EXPOSIMU 2026")
    print("MODELO 4: MODELOS BASADOS EN AGENTES - ABM (CAZADOR FURTIVO)")
    print(f"Timestamp: {timestamp} | Usuario: {user}")
    print("Generador PRNG integrado: Congruencial Mixto (Knuth: a=1664525, c=1013904223, m=2^32)")
    print("=" * 80)

    configs = [1, 2, 3]

    print("\nTABLA DE VALIDACIÓN EXPERIMENTAL (3 CONFIGURACIONES, N=1,000 réplicas):")
    print(f"{'Config':<8} | {'Escenario y Densidad':<36} | {'Pasos Teo (dM)':<15} | {'Pasos Sim':<12} | {'Dif (%)':<8} | {'Efectividad':<12}")
    print("-" * 100)

    teo_steps = []
    sim_steps = []
    labels = []

    for cfg_id in configs:
        pcs, d_teo, desc = get_pieces_config(cfg_id)
        obs_steps = []
        successes = 0

        for r in range(1000):
            agent = HunterAgentABM(origin=(3, 3), seed=20260101 + r)
            c_step, _ = agent.simulate(pcs)
            if c_step is not None:
                obs_steps.append(c_step)
                successes += 1

        avg_step = np.mean(obs_steps)
        dif_pct = abs(avg_step - d_teo) / d_teo * 100.0
        eff = (successes / 1000.0) * 100.0

        teo_steps.append(d_teo)
        sim_steps.append(avg_step)
        labels.append(f"Config {cfg_id}\n(dM={int(d_teo)})")

        print(f"Config {cfg_id:<1} | {desc:<36} | {d_teo:<15.2f} | {avg_step:<12.2f} | {dif_pct:<8.2f}% | {eff:<12.1f}%")

    # Gráfica de Validación
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6), dpi=300)
    x = np.arange(len(configs))
    w = 0.35

    ax1.bar(x - w/2, teo_steps, w, label="Pasos Mínimos Teóricos (dM Manhattan)", color='#2c3e50', edgecolor='black')
    ax1.bar(x + w/2, sim_steps, w, label="Pasos Medios Simulados (ABM)", color='#8e44ad', edgecolor='black')
    ax1.set_title("Validación: Pasos hasta Primera Captura del Cazador", fontsize=11, fontweight='semibold')
    ax1.set_xticks(x)
    ax1.set_xticklabels(labels)
    ax1.set_ylabel("Número de Pasos", fontsize=10)
    ax1.set_ylim(0, 8)
    ax1.grid(True, alpha=0.3, axis='y')
    ax1.legend()

    # Heatmap representativo del Cazador en Config 1
    heat = np.zeros((8, 8))
    pcs1, _, _ = get_pieces_config(1)
    for r in range(500):
        agent = HunterAgentABM(origin=(3, 3), seed=20260101 + r)
        _, path = agent.simulate(pcs1)
        for p in path:
            heat[p[1], p[0]] += 1

    im = ax2.imshow(heat / np.sum(heat), origin='lower', cmap='Purples', extent=[0, 8, 0, 8])
    ax2.set_title("Densidad Espacial del Cazador desde d4 hacia Filas 1 y 6", fontsize=11, fontweight='semibold')
    ax2.set_xticks(np.arange(0.5, 8.5, 1))
    ax2.set_yticks(np.arange(0.5, 8.5, 1))
    ax2.set_xticklabels(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'])
    ax2.set_yticklabels(['1', '2', '3', '4', '5', '6', '7', '8'])
    fig.colorbar(im, ax=ax2, fraction=0.046, pad=0.04, label="Densidad de Ocupación")

    plt.tight_layout()
    fig_path = os.path.join(OUTPUT_DIR, "daza_tocarruncho_figueredo_useche_sanchez_modelo4_agentes.png")
    plt.savefig(fig_path, dpi=300)
    plt.close()
    print(f"\n[OK] Gráfica de validación guardada en: {fig_path}")

    # Respuestas al Análisis de Sensibilidad (Página 8 de la Guía)
    print("\nANÁLISIS DE SENSIBILIDAD:")
    print("1. ¿Qué parámetro tiene mayor impacto en los resultados?")
    print("   La distancia Manhattan mínima a la presa más cercana. Al dispersarse las piezas de dM=2 a dM=6,")
    print(f"   el tiempo medio de caza se triplica exactamente en un {(sim_steps[2]-sim_steps[0])/sim_steps[0]*100:.1f}%.")
    print("2. ¿Los resultados coinciden con la teoría? Si hay discrepancias, explicar posibles causas:")
    print("   Coinciden exactamente (diferencia 0.00%) con la distancia Manhattan teórica óptima, ya que la política")
    print("   voraz siempre reduce la distancia ortogonal sin desviaciones innecesarias.")
    print("3. Identificar una limitación del modelo en su forma actual:")
    print("   El cazador es puramente miope y reactivo; no evalúa el valor estratégico de las piezas (peón vs rey)")
    print("   ni anticipa si una casilla está amenazada o defendida por el jugador.")
    print("=" * 80)


if __name__ == "__main__":
    main()
