import sys
import time

def fib(n: int) -> int:
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

def bench_n(target_n: int, runs: int):
    # Warm-up de 5 iterações para estabilizar o Specialized Adaptive Interpreter do Python 3.12
    for _ in range(5):
        _ = fib(target_n)

    times = []
    last_res = 0

    for _ in range(runs):
        t0 = time.perf_counter_ns()
        last_res = fib(target_n)
        t1 = time.perf_counter_ns()
        elapsed_us = (t1 - t0) // 1000
        times.append(elapsed_us)

    mean_us = sum(times) // runs
    min_us = min(times)
    max_us = max(times)

    print(f"fib({target_n}) = {last_res} | Media: {mean_us} us | Min: {min_us} us | Max: {max_us} us ({runs} repeticoes)")

def main():
    if len(sys.argv) > 1:
        try:
            n = int(sys.argv[1])
        except ValueError:
            n = 26
        runs = 10 if n >= 32 else 50
        print("==================================================================")
        print("   PYTHON 3.12 - EXECUCAO DINAMICA VIA ARGV")
        print(f"   (Argumento n = {n} recebido via linha de comando)")
        print("==================================================================")
        bench_n(n, runs)
        return

    print("==================================================================")
    print("   PYTHON 3.12 - BATERIA COMPLETA DE BENCHMARKS")
    print("   (Warm-up de 5 repeticoes + 50 iteracoes com time.perf_counter_ns)")
    print("==================================================================")

    bench_n(20, 50)
    bench_n(24, 50)
    bench_n(26, 50)
    bench_n(28, 50)
    bench_n(30, 20)
    bench_n(32, 10)
    bench_n(34, 5)

if __name__ == "__main__":
    main()
