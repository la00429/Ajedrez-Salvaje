"""
runner.py - Orquestador general de simulaciones y calibraciones en Python
Ejecuta los 5 módulos de simulación en orden y consolida las salidas.
Nomenclatura oficial UPTC: daza_tocarruncho_figueredo_useche_sanchez_modelo[1-5].py
"""

import os
import subprocess
import sys

SCRIPTS = [
    ("01_rng_lehmer.py", "Validación Estadística de Generadores Pseudoaleatorios (PRNG)"),
    ("daza_tocarruncho_figueredo_useche_sanchez_modelo1_caminatas.py", "Modelo 1: Caminatas Aleatorias 2D"),
    ("daza_tocarruncho_figueredo_useche_sanchez_modelo2_colas.py", "Modelo 2: Sistemas de Colas M/M/1"),
    ("daza_tocarruncho_figueredo_useche_sanchez_modelo3_montecarlo.py", "Modelo 3: Simulación Monte Carlo"),
    ("daza_tocarruncho_figueredo_useche_sanchez_modelo4_agentes.py", "Modelo 4: Sistemas Basados en Agentes (ABM)"),
    ("daza_tocarruncho_figueredo_useche_sanchez_modelo5_dinamica.py", "Modelo 5: Dinámica de Sistemas")
]

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    print("=" * 80)
    print("ORQUESTADOR DE SIMULACIONES Y EXPERIMENTACIÓN EN PYTHON - EXPOSIMU 2026")
    print("Integrantes: Daza, Tocarruncho, Figueredo, Useche, Sanchez")
    print("=" * 80)

    for script_name, desc in SCRIPTS:
        script_path = os.path.join(base_dir, script_name)
        print(f"\n--> Ejecutando: {script_name} ({desc})...")
        res = subprocess.run([sys.executable, script_path], capture_output=True, text=True)
        if res.returncode == 0:
            print(f"[OK] {script_name} finalizó con éxito.")
        else:
            print(f"[ERROR] {script_name} falló con código {res.returncode}:")
            print(res.stderr)
            sys.exit(1)

    print("\n" + "=" * 80)
    print("TODAS LAS SIMULACIONES Y GRÁFICAS SE GENERARON CORRECTAMENTE EN:")
    print(os.path.join(base_dir, "graficas"))
    print("=" * 80)

if __name__ == "__main__":
    main()
