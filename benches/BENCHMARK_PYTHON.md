# 🐍 Relatório de Benchmarks — Python 3.14 (CPython) no Linux

Este documento consolida todas as medições de benchmark executadas com **Python 3.14 (CPython)** no ambiente Linux.

---

## 1. Ambiente de Execução

- **Interpretador:** CPython 3.14.7
- **Otimizações:** Specialized Adaptive Interpreter ativo (estabilizado via 5 ciclos de warm-up)
- **Temporização:** `time.perf_counter_ns()` com resolução de nanossegundos convertida em microssegundos
- **Hardware:** Genuine Intel(R) CPU 0000 @ 2.60 GHz (8 vCPUs / threads), 16 GB RAM
- **Kernel:** Linux 6.18.53 x86_64

---

## 2. Bateria Estatística de Fibonacci Recursivo

Execução via `benches/fib_bench.py` com 5 ciclos prévios de warm-up:

| $n$ | Repetições | Média ($\mu$s) | Mediana ($\mu$s) | Mínimo ($\mu$s) | Máximo ($\mu$s) | Tempo Total da Bateria |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **20** | 50 | 1.971 $\mu$s | **1.798 $\mu$s** | 1.352 $\mu$s | 4.199 $\mu$s | 98,5 ms |
| **24** | 50 | 9.491 $\mu$s | **9.480 $\mu$s** | 9.263 $\mu$s | 10.068 $\mu$s | 474,5 ms |
| **26** | 50 | 24.657 $\mu$s | **24.668 $\mu$s** | 24.511 $\mu$s | 24.983 $\mu$s | 1.232 ms |
| **28** | 50 | 64.718 $\mu$s | **64.554 $\mu$s** | 64.067 $\mu$s | 68.003 $\mu$s | 3.235 ms |
| **30** | 20 | 170.392 $\mu$s | **170.425 $\mu$s** | 169.563 $\mu$s | 171.669 $\mu$s | 3.407 ms |
| **32** | 10 | 447.920 $\mu$s | **444.811 $\mu$s** | 440.274 $\mu$s | 469.389 $\mu$s | 4.479 ms |
| **34** | 10 | 1.157.695 $\mu$s | **1.158.003 $\mu$s** | 1.148.394 $\mu$s | 1.168.691 $\mu$s | 11.576 ms |

---

## 3. Suíte de Operações Gerais (Loops e Structs)

Execução via `benches/suite_bench.py` (utilizando classes com `__slots__` para otimização máxima de memória):

| Teste | Descrição da Operação | Tempo Medido |
|---|---|:---:|
| **Teste 1** | Recursão Profunda: `fib(26)` | **25,01 ms** (25.007 $\mu$s) |
| **Teste 2** | Loop Aritmético: 50.000 iterações com float e int | **6,24 ms** (6.240 $\mu$s) |
| **Teste 3** | Heap & Structs: 10.000 instâncias de `Ponto3D` com `math.sqrt` | **6,33 ms** (6.331 $\mu$s) |
| **TOTAL** | Tempo Total da Suíte Consolidada | **37,58 ms** |

---

## 4. Instruções de Execução

```bash
# Executar a bateria estatística completa de Fibonacci:
python3 benches/fib_bench.py

# Executar caso dinâmico específico via linha de comando:
python3 benches/fib_bench.py 26

# Executar suíte de loops e structs:
python3 benches/suite_bench.py
```
