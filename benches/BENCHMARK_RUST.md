# 🦀 Relatório de Benchmarks — Rust Nativo (LLVM -O3) no Linux

Este documento consolida todas as medições de benchmark executadas com **Rust Nativo** no ambiente Linux, utilizando o compilador oficial `rustc 1.98.1` com otimizações de nível 3 (`-C opt-level=3`).

---

## 1. Ambiente de Execução

- **Compilador:** `rustc 1.98.1 (48a229cea 2026-09-01)`
- **Cargo:** `cargo 1.98.1 (797e8a9bc 2026-08-05)`
- **Flags de Otimização:** `-C opt-level=3`
- **Mecanismos Anti-Otimização:** `std::hint::black_box` em argumentos e retornos
- **Hardware:** Genuine Intel(R) CPU 0000 @ 2.60 GHz (8 vCPUs / threads), 16 GB RAM
- **Kernel:** Linux 6.18.53 x86_64

---

## 2. Bateria Estatística de Fibonacci Recursivo

Execução via `benches/fib_native.rs` com 5 ciclos prévios de warm-up:

| $n$ | Repetições | Média ($\mu$s) | Mediana ($\mu$s) | Mínimo ($\mu$s) | Máximo ($\mu$s) | Tempo Total da Bateria |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **20** | 50 | 40 $\mu$s | **37 $\mu$s** | 33 $\mu$s | 54 $\mu$s | 2,0 ms |
| **24** | 50 | 208 $\mu$s | **178 $\mu$s** | 178 $\mu$s | 319 $\mu$s | 10,4 ms |
| **26** | 50 | 508 $\mu$s | **470 $\mu$s** | 466 $\mu$s | 766 $\mu$s | 25,4 ms |
| **28** | 50 | 1.343 $\mu$s | **1.235 $\mu$s** | 1.225 $\mu$s | 2.013 $\mu$s | 67,1 ms |
| **30** | 30 | 3.231 $\mu$s | **3.218 $\mu$s** | 3.208 $\mu$s | 3.394 $\mu$s | 96,9 ms |
| **32** | 20 | 8.496 $\mu$s | **8.511 $\mu$s** | 8.416 $\mu$s | 8.576 $\mu$s | 169,9 ms |
| **34** | 15 | 22.056 $\mu$s | **22.055 $\mu$s** | 22.037 $\mu$s | 22.092 $\mu$s | 330,8 ms |

---

## 3. Suíte de Operações Gerais (Loops e Structs)

Execução via `benches/suite_native.rs`:

| Teste | Descrição da Operação | Tempo Medido |
|---|---|:---:|
| **Teste 1** | Recursão Profunda: `fib(26)` | **0,516 ms** (515 $\mu$s) |
| **Teste 2** | Loop Aritmético: 50.000 iterações | **0,102 ms** (101 $\mu$s) |
| **Teste 3** | Heap & Structs: 10.000 instâncias de `Ponto3D` com raiz quadrada | **0,058 ms** (57 $\mu$s) |
| **TOTAL** | Tempo Total da Suíte Consolidada | **0,675 ms** |

---

## 4. Instruções de Compilação e Execução

```bash
# Compilar binários otimizados com LLVM -O3:
rustc -C opt-level=3 benches/fib_native.rs -o benches/fib_native
rustc -C opt-level=3 benches/suite_native.rs -o benches/suite_native

# Executar bateria de Fibonacci:
./benches/fib_native

# Executar caso dinâmico específico via linha de comando:
./benches/fib_native 26

# Executar suíte de loops e structs:
./benches/suite_native
```
