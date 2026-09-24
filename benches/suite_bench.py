import math
import sys
import time

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

def fib(n: int) -> int:
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

class Ponto3D:
    __slots__ = ("x", "y", "z")
    def __init__(self, x: float, y: float, z: float):
        self.x = x
        self.y = y
        self.z = z

def main():
    print("╔══════════════════════════════════════════════════════════════════════╗")
    print("║               PYTHON 3.14 - BENCHMARK SUITE                         ║")
    print("╚══════════════════════════════════════════════════════════════════════╝\n")

    # 1. Fibonacci(26)
    t0 = time.perf_counter_ns()
    res_fib = fib(26)
    t_fib_ns = time.perf_counter_ns() - t0
    t_fib_ms = t_fib_ns / 1_000_000
    t_fib_us = t_fib_ns // 1000
    print(f"→ Teste 1: Recursão Profunda - Fibonacci(26)")
    print(f"  • Resultado: fib(26) = {res_fib}")
    print(f"  • Tempo decorrido: {t_fib_ms:.2f} ms ({t_fib_us} us)\n")

    # 2. Loop Aritmético (50.000 iterações)
    t0 = time.perf_counter_ns()
    acumulador = 0.0
    for i in range(1, 50001):
        acumulador += (i * 1.5) - (i / 2.0)
    t_loop_ns = time.perf_counter_ns() - t0
    t_loop_ms = t_loop_ns / 1_000_000
    t_loop_us = t_loop_ns // 1000
    print(f"→ Teste 2: Loop Aritmético (50.000 iterações)")
    print(f"  • Acumulador final: {acumulador}")
    print(f"  • Tempo decorrido:  {t_loop_ms:.2f} ms ({t_loop_us} us)\n")

    # 3. Structs (10.000 instâncias)
    t0 = time.perf_counter_ns()
    soma_distancias = 0.0
    for j in range(1, 10001):
        p = Ponto3D(j * 1.0, j * 2.0, j * 3.0)
        soma_distancias += math.sqrt(p.x * p.x + p.y * p.y + p.z * p.z)
    t_struct_ns = time.perf_counter_ns() - t0
    t_struct_ms = t_struct_ns / 1_000_000
    t_struct_us = t_struct_ns // 1000
    print(f"→ Teste 3: Criação e Manipulação de Structs (10.000 instâncias)")
    print(f"  • Soma das distâncias: {soma_distancias}")
    print(f"  • Tempo decorrido:     {t_struct_ms:.2f} ms ({t_struct_us} us)\n")

    t_total_ms = t_fib_ms + t_loop_ms + t_struct_ms
    print("========================================================================")
    print("  RESULTADOS CONSOLIDADOS - PYTHON 3.14 🐍")
    print(f"  • Recursão de CallFrames (Fib 26): {t_fib_ms:.2f} ms")
    print(f"  • Dispatch de Loop (50k ops):      {t_loop_ms:.2f} ms")
    print(f"  • Heap & Structs (10k instâncias): {t_struct_ms:.2f} ms")
    print(f"  • TEMPO TOTAL DA SUÍTE:            {t_total_ms:.2f} ms")
    print("========================================================================\n")

if __name__ == "__main__":
    main()
