"""
01_rng_lehmer.py - Calibración y Validación de Generadores de Números Pseudoaleatorios (RNG)
Modelos:
1. Generador Congruencial Mixto (LCG): X_{n+1} = (a * X_n + c) mod m
   Parámetros Knuth / Numerical Recipes: a = 1664525, c = 1013904223, m = 2^32
2. Generador Congruencial Multiplicativo (Lehmer / Park-Miller MINSTD): X_{n+1} = (a * X_n) mod m
   Parámetros Park-Miller: a = 16807 (7^5), m = 2^31 - 1 (2147483647)

Pruebas estadísticas:
- Teorema de Hull-Dobell para período completo.
- Prueba de bondad de ajuste Chi-cuadrada (Uniformidad U(0,1)).
- Gráfico de dispersión 2D (Lag Plot) para evaluar ausencia de hiperplanos o patrones espaciales.
- Histograma de frecuencias vs densidad uniforme teórica.
"""

import os
import math
import numpy as np
import scipy.stats as stats
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "graficas")
os.makedirs(OUTPUT_DIR, exist_ok=True)


class MixedCongruential:
    """Generador Congruencial Mixto implementado en Ajedrez Salvaje."""
    DEFAULT_MULTIPLIER = 1664525
    DEFAULT_INCREMENT = 1013904223
    DEFAULT_MODULUS = 4294967296  # 2^32

    def __init__(self, x0=20260101, a=DEFAULT_MULTIPLIER, c=DEFAULT_INCREMENT, m=DEFAULT_MODULUS):
        self.x0 = x0 % m
        self.a = a
        self.c = c
        self.m = m
        self.x = self.x0

    def next_x(self):
        self.x = (self.a * self.x + self.c) % self.m
        return self.x

    def next_r(self):
        return self.next_x() / self.m

    def generate_sequence(self, n):
        return [self.next_r() for _ in range(n)]

    def check_hull_dobell(self):
        """Verifica las 3 condiciones del Teorema de Hull-Dobell para período máximo m."""
        c_m_coprime = math.gcd(self.c, self.m) == 1
        div_p = (self.a - 1) % 2 == 0
        div_4 = (self.a - 1) % 4 == 0
        return {
            "c_coprime_m": c_m_coprime,
            "a_minus_1_div_primes": div_p,
            "a_minus_1_div_4": div_4,
            "full_period_guaranteed": c_m_coprime and div_p and div_4
        }


class MultiplicativeCongruential:
    """Generador de Lehmer (Park-Miller MINSTD) usado en la retroexcavadora."""
    DEFAULT_MULTIPLIER = 16807  # 7^5
    DEFAULT_MODULUS = 2147483647  # 2^31 - 1 (primo de Mersenne)

    def __init__(self, x0=20260101, a=DEFAULT_MULTIPLIER, m=DEFAULT_MODULUS):
        self.m = m
        self.a = a
        self.x0 = max(1, x0 % m)
        self.x = self.x0

    def next_x(self):
        self.x = (self.a * self.x) % self.m
        return self.x

    def next_r(self):
        return self.next_x() / self.m

    def generate_sequence(self, n):
        return [self.next_r() for _ in range(n)]


def chi_square_uniformity_test(data, k=10, alpha=0.05):
    """Prueba de Chi-cuadrada para uniformidad en [0, 1) con k intervalos equiprobables."""
    n = len(data)
    expected = n / k
    bins = np.linspace(0.0, 1.0, k + 1)
    observed, _ = np.histogram(data, bins=bins)
    
    chi2_stat = np.sum((observed - expected) ** 2 / expected)
    df = k - 1
    critical_val = stats.chi2.ppf(1.0 - alpha, df)
    p_value = 1.0 - stats.chi2.cdf(chi2_stat, df)
    passed = chi2_stat < critical_val

    return {
        "n": n,
        "k": k,
        "observed": observed.tolist(),
        "expected": expected,
        "chi2_stat": float(chi2_stat),
        "df": df,
        "critical_val": float(critical_val),
        "p_value": float(p_value),
        "passed": bool(passed)
    }


def plot_rng_validation(seq_mixed, seq_lehmer, chi_mixed, chi_lehmer):
    """Genera panel de figuras científicas con histograma y lag plot."""
    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
    fig, axes = plt.subplots(2, 2, figsize=(14, 10), dpi=300)
    fig.suptitle("Calibración y Validación de Generadores Pseudoaleatorios (RNG)", fontsize=16, fontweight='bold', y=0.98)

    # 1. Histograma LCG Mixto
    ax1 = axes[0, 0]
    n_bins = 20
    ax1.hist(seq_mixed, bins=n_bins, range=(0, 1), density=True, color='#2b5c8f', alpha=0.75, edgecolor='black', linewidth=0.8)
    ax1.axhline(1.0, color='#d9534f', linestyle='--', linewidth=2, label=r"Densidad Teórica $U(0, 1)$")
    title_mixed = rf"Histograma: LCG Mixto (Knuth 64-bit)" + "\n" + rf"$\chi^2 = {chi_mixed['chi2_stat']:.3f}$ (p = {chi_mixed['p_value']:.4f}) - {'PASA' if chi_mixed['passed'] else 'FALLA'}"
    ax1.set_title(title_mixed, fontsize=11, fontweight='semibold')
    ax1.set_xlabel(r"Valor pseudoaleatorio $U_i$", fontsize=10)
    ax1.set_ylabel("Densidad de probabilidad", fontsize=10)
    ax1.set_xlim(0, 1)
    ax1.set_ylim(0, 1.4)
    ax1.legend(loc='upper right', frameon=True)

    # 2. Lag Plot LCG Mixto (Ui vs Ui+1)
    ax2 = axes[0, 1]
    ax2.scatter(seq_mixed[:-1][:3000], seq_mixed[1:][:3000], s=3, color='#2b5c8f', alpha=0.4, edgecolors='none')
    ax2.set_title(r"Gráfico de Dispersión / Lag Plot: LCG Mixto ($U_i$ vs $U_{i+1}$)", fontsize=11, fontweight='semibold')
    ax2.set_xlabel(r"$U_i$", fontsize=10)
    ax2.set_ylabel(r"$U_{i+1}$", fontsize=10)
    ax2.set_xlim(0, 1)
    ax2.set_ylim(0, 1)

    # 3. Histograma Lehmer
    ax3 = axes[1, 0]
    ax3.hist(seq_lehmer, bins=n_bins, range=(0, 1), density=True, color='#2e7d32', alpha=0.75, edgecolor='black', linewidth=0.8)
    ax3.axhline(1.0, color='#d9534f', linestyle='--', linewidth=2, label=r"Densidad Teórica $U(0, 1)$")
    title_lehmer = rf"Histograma: Lehmer Multiplicativo (Park-Miller MINSTD)" + "\n" + rf"$\chi^2 = {chi_lehmer['chi2_stat']:.3f}$ (p = {chi_lehmer['p_value']:.4f}) - {'PASA' if chi_lehmer['passed'] else 'FALLA'}"
    ax3.set_title(title_lehmer, fontsize=11, fontweight='semibold')
    ax3.set_xlabel(r"Valor pseudoaleatorio $U_i$", fontsize=10)
    ax3.set_ylabel("Densidad de probabilidad", fontsize=10)
    ax3.set_xlim(0, 1)
    ax3.set_ylim(0, 1.4)
    ax3.legend(loc='upper right', frameon=True)

    # 4. Lag Plot Lehmer
    ax4 = axes[1, 1]
    ax4.scatter(seq_lehmer[:-1][:3000], seq_lehmer[1:][:3000], s=3, color='#2e7d32', alpha=0.4, edgecolors='none')
    ax4.set_title(r"Gráfico de Dispersión / Lag Plot: Lehmer ($U_i$ vs $U_{i+1}$)", fontsize=11, fontweight='semibold')
    ax4.set_xlabel(r"$U_i$", fontsize=10)
    ax4.set_ylabel(r"$U_{i+1}$", fontsize=10)
    ax4.set_xlim(0, 1)
    ax4.set_ylim(0, 1)

    plt.tight_layout()
    output_path = os.path.join(OUTPUT_DIR, "01_rng_calibracion.png")
    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"[OK] Gráfica guardada en: {output_path}")


def main():
    print("=" * 80)
    print("EJECUTANDO CALIBRACIÓN Y PRUEBAS ESTADÍSTICAS DE GENERADORES (RNG)")
    print("=" * 80)

    seed = 20260101
    n_samples = 10000

    # 1. Congruencial Mixto
    lcg = MixedCongruential(x0=seed)
    hd_report = lcg.check_hull_dobell()
    print("\n1. Generador Congruencial Mixto (Knuth):")
    print(f"   Ecuación: X_(n+1) = ({lcg.a} * X_n + {lcg.c}) mod {lcg.m}")
    print(f"   Semilla inicial (x0): {seed}")
    print("   Teorema de Hull-Dobell (Período Completo = 2^32):")
    print(f"     - c y m son primos relativos: {hd_report['c_coprime_m']}")
    print(f"     - (a - 1) es divisible por factores primos de m: {hd_report['a_minus_1_div_primes']}")
    print(f"     - (a - 1) es divisible por 4: {hd_report['a_minus_1_div_4']}")
    print(f"     -> Garantía de Período Máximo: {'CUMPLE' if hd_report['full_period_guaranteed'] else 'NO CUMPLE'}")

    seq_mixed = lcg.generate_sequence(n_samples)
    chi_mixed = chi_square_uniformity_test(seq_mixed, k=10)
    print(f"   Prueba Chi-cuadrada (k=10, n={n_samples}):")
    print(f"     Estadístico Chi2: {chi_mixed['chi2_stat']:.4f}")
    print(f"     Valor Crítico (alfa=0.05, df=9): {chi_mixed['critical_val']:.4f}")
    print(f"     p-valor: {chi_mixed['p_value']:.4f}")
    print(f"     Veredicto: {'ACEPTA H0 (Uniformidad validada)' if chi_mixed['passed'] else 'RECHAZA H0'}")

    # 2. Lehmer Multiplicativo
    lehmer = MultiplicativeCongruential(x0=seed)
    print("\n2. Generador de Lehmer Multiplicativo (Park-Miller MINSTD):")
    print(f"   Ecuación: X_(n+1) = ({lehmer.a} * X_n) mod {lehmer.m}")
    print(f"   Semilla inicial (x0): {lehmer.x0}")
    print(f"   Período máximo teórico: m - 1 = {lehmer.m - 1}")

    seq_lehmer = lehmer.generate_sequence(n_samples)
    chi_lehmer = chi_square_uniformity_test(seq_lehmer, k=10)
    print(f"   Prueba Chi-cuadrada (k=10, n={n_samples}):")
    print(f"     Estadístico Chi2: {chi_lehmer['chi2_stat']:.4f}")
    print(f"     Valor Crítico (alfa=0.05, df=9): {chi_lehmer['critical_val']:.4f}")
    print(f"     p-valor: {chi_lehmer['p_value']:.4f}")
    print(f"     Veredicto: {'ACEPTA H0 (Uniformidad validada)' if chi_lehmer['passed'] else 'RECHAZA H0'}")

    # Graficar
    plot_rng_validation(seq_mixed, seq_lehmer, chi_mixed, chi_lehmer)
    print("\n[OK] Script 01_rng_lehmer.py completado con éxito.")


if __name__ == "__main__":
    main()
