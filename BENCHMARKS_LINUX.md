# 🚀 Kaz — Relatório Oficial de Benchmarks & Verificação de Desempenho no Linux

Este documento estabelece o relatório oficial de benchmarks da linguagem **Kaz** no ambiente **Linux x86_64**, consolidando a replicação experimental rigorosa com resolução de microssegundos em paridade simétrica entre **Rust Nativo (LLVM -O3)**, **Kaz Cranelift JIT**, **Python 3.14 (CPython)** e a **Kaz Bytecode VM**.

> 🪟 **Relatório Original Windows 11:** Para conferir os benchmarks originais executados no **Windows 11 com Python 3.12**, consulte o **[Relatório de Benchmarks no Windows (BENCHMARKS.md)](BENCHMARKS.md)**.

---

## 1. Ambiente de Testes & Especificações de Hardware

Todos os testes deste relatório foram executados na mesma máquina física e no mesmo ambiente de sistema operacional:

- **Processador:** Genuine Intel(R) CPU 0000 @ 2.60 GHz (4 Núcleos Físicos, 8 Threads)
- **Memória RAM:** 16 GB DDR4
- **Sistema Operacional:** Linux GNU/Linux (Kernel `6.18.53-nux #1 SMP PREEMPT_DYNAMIC x86_64`)
- **Backend Nativo Kaz:** Cranelift Code Generator (Compilado em Release Mode)
- **Gerador de Binários Kaz:** `kaz build` gerando executáveis autônomos ELF
- **Compilador Rust de Referência:** `rustc 1.98.1 (48a229cea 2026-09-01)` (LLVM Backend com `-C opt-level=3`)
- **Interpretador Python de Referência:** CPython 3.14.7

---

## 2. Refutação Matemática de *Constant Folding* & Escalonamento Assintótico

A complexidade assintótica teórica da recursão ingênua de Fibonacci escala proporcionalmente à razão áurea:

$$O(\phi^n) \quad \text{onde} \quad \phi \approx 1{,}6180339887$$

Para cada incremento de $\Delta n = 2$, o número total de chamadas e o tempo esperado devem crescer por um fator de:

$$\phi^2 \approx (1{,}6180339887)^2 \approx 2{,}6180339887$$

Se houvesse *Constant Folding*, o tempo seria plano ($\le 1\ \mu\text{s}$) para qualquer $n$. Veja a progressão real medida no **Kaz JIT** no Linux:

| $n$ | Chamadas de Função | Tempo Esperado ($\times 2{,}618$) | Tempo Real Medido (Kaz JIT) | Variação Teórica |
|:---:|:---:|:---:|:---:|:---:|
| **24** | 92.693 | — | **381 $\mu$s** | Baseline |
| **26** | 242.785 | $\approx 997\ \mu\text{s}$ | **990 $\mu$s** | **-0,7%** |
| **28** | 635.621 | $\approx 2.592\ \mu\text{s}$ | **2.590 $\mu$s** | **-0,1%** |
| **30** | 1.664.079 | $\approx 6.781\ \mu\text{s}$ | **6.769 $\mu$s** | **-0,2%** |
| **32** | 4.356.521 | $\approx 17.721\ \mu\text{s}$ | **17.696 $\mu$s** | **-0,1%** |
| **34** | 11.405.039 | $\approx 46.328\ \mu\text{s}$ | **46.597 $\mu$s** | **+0,6%** |

> **Conclusão:** A correlação entre o tempo de execução medido no Linux e o crescimento assintótico teórico $O(\phi^n)$ é superior a **99,8%**. Todas as instruções recursivas foram executadas diretamente na CPU.

---

## 3. Metodologia de Medição 100% Simétrica

1. **Anti-Constant Folding Dinâmico:**
   - **Kaz JIT & VM:** Parâmetro $n$ derivado em runtime via clock do sistema (`time_now_us() % 2`) ou recebido via linha de comando (`argv_int(0)`) / stream (`input_int()`).
   - **Rust Nativo (`-O3`):** Parâmetro $n$ recebido via CLI e isolado com duplo `std::hint::black_box` (no argumento e no retorno da função).
   - **Python 3.14:** Parâmetro $n$ recebido via CLI (`sys.argv[1]`).
2. **Proteção contra *Loop-Invariant Code Motion (LICM)*:**
   - Previne que compiladores agressivos (como LLVM ou Cranelift) desloquem a recursão para fora dos loops de benchmark.
3. **Ciclo de Aquecimento Idêntico (Warm-up):**
   - 5 iterações completas não cronometradas antes de cada teste em todas as tecnologias para aquecer caches L1/L2 e estabilizar o interpretador adaptativo.
4. **Resolução de Microssegundos ($\mu$s):**
   - **Kaz:** `time_now_us()` ancorado em contador de alta precisão.
   - **Rust:** `std::time::Instant::now().elapsed().as_micros()`.
   - **Python:** `time.perf_counter_ns() // 1000`.

---

## 4. Tabela Comparativa de Desempenho Simétrico (Linux)

Resultados consolidados com **Mediana**, **Média** e o intervalo **[Mínimo – Máximo]** em microssegundos ($\mu$s):

| $n$ | Rust Nativo (-O3 / LLVM) | Kaz JIT (Cranelift) | Python 3.14 (CPython) | Kaz VM (Bytecode Interpreter) | Paridade Kaz JIT vs Rust -O3 (Mediana) | Aceleração Kaz JIT vs Python 3.14 | Aceleração Kaz JIT vs Kaz VM |
|:---:|---|---|---|---|:---:|:---:|:---:|
| **20** | **37 $\mu$s** (Méd: 40, [33 – 54]) | **58 $\mu$s** (Min: 54, Max: 76) | **1.798 $\mu$s** (Méd: 1.971, [1.352 – 4.199]) | **21.217 $\mu$s** (~21 ms) | **1,56x** | **31,0x mais rápido** | **365x mais rápido** |
| **24** | **178 $\mu$s** (Méd: 208, [178 – 319]) | **381 $\mu$s** (Min: 369, Max: 442) | **9.480 $\mu$s** (Méd: 9.491, [9.263 – 10.068]) | **144.459 $\mu$s** (~144 ms) | **2,14x** | **24,9x mais rápido** | **379x mais rápido** |
| **26** | **470 $\mu$s** (Méd: 508, [466 – 766]) | **990 $\mu$s** (Min: 967, Max: 1.048) | **24.668 $\mu$s** (Méd: 24.657, [24.511 – 24.983]) | **384.260 $\mu$s** (~384 ms) | **2,10x** | **24,9x mais rápido** | **388x mais rápido** |
| **28** | **1.235 $\mu$s** (Méd: 1.343, [1.225 – 2.013]) | **2.590 $\mu$s** (Min: 2.537, Max: 2.661) | **64.554 $\mu$s** (Méd: 64.718, [64.067 – 68.003]) | **971.813 $\mu$s** (~971 ms) | **2,09x** | **24,9x mais rápido** | **375x mais rápido** |
| **30** | **3.218 $\mu$s** (Méd: 3.231, [3.208 – 3.394]) | **6.769 $\mu$s** (Min: 6.700, Max: 6.839) | **170.425 $\mu$s** (Méd: 170.392, [169.563 – 171.669]) | **2.543.188 $\mu$s** (~2.543 ms) | **2,10x** | **25,1x mais rápido** | **375x mais rápido** |
| **32** | **8.511 $\mu$s** (Méd: 8.496, [8.416 – 8.576]) | **17.696 $\mu$s** (Min: 17.578, Max: 17.889) | **444.811 $\mu$s** (Méd: 447.920, [440.274 – 469.389]) | **6.735.419 $\mu$s** (~6.735 ms) | **2,08x** | **25,1x mais rápido** | **380x mais rápido** |
| **34** | **22.055 $\mu$s** (Méd: 22.056, [22.037 – 22.092]) | **46.597 $\mu$s** (Min: 46.141, Max: 47.256) | **1.158.003 $\mu$s** (Méd: 1.157.695, [1.148.394 – 1.168.691]) | **17.435.759 $\mu$s** (~17.435 ms) | **2,11x** | **24,8x mais rápido** | **374x mais rápido** |

---

## 5. Suíte Geral de Performance (Recursão, Loops e Structs)

Comparativo na suíte de testes sintéticos integrados (`examples/benchmark.kaz`):

| Teste | Rust Nativo (-O3) | Kaz Cranelift JIT | Python 3.14 | Kaz Bytecode VM |
|---|:---:|:---:|:---:|:---:|
| **Recursão (Fib 26)** | 0,516 ms (515 $\mu$s) | 0,990 ms (990 $\mu$s) | 25,01 ms (25.007 $\mu$s) | 391 ms |
| **Loop Aritmético (50k iterações)** | 0,102 ms (101 $\mu$s) | < 0,5 ms (~0 ms) | 6,24 ms (6.240 $\mu$s) | 34 ms |
| **Structs & Heap (10k instâncias)** | 0,058 ms (57 $\mu$s) | ~1,0 ms (~1.000 $\mu$s) | 6,33 ms (6.331 $\mu$s) | 29 ms |
| **TEMPO TOTAL DA SUÍTE** | **0,675 ms** | **~2,0 ms** | **37,58 ms** | **454 ms** |

---

## 6. Documentação Detalhada por Teste & Tecnologia

Para conferir o detalhamento metodológico, dados estatísticos completos e comandos de reprodução isolados:

### Por Tipo de Teste
- [📊 Teste 1: Bateria Estatística Completa de Fibonacci (n = 20 a 34)](benches/TESTE_1_FIBONACCI_ESTATISTICO.md)
- [🛡️ Teste 2: Execução Dinâmica via Linha de Comando (Argv/Stdin) e Anti-Constant Folding](benches/TESTE_2_EXECUCAO_DINAMICA_ARGV.md)
- [📐 Teste 3: Verificação de Complexidade Assintótica Exponencial O(φⁿ)](benches/TESTE_3_SCALING_EXPONENCIAL_O_PHI.md)
- [⚡ Teste 4: Suíte Geral de Performance (Recursão, Loops 50k e Structs 10k)](benches/TESTE_4_SUITE_GERAL_LOOPS_STRUCTS.md)

### Por Tecnologia
- [🦀 Relatório Dedicado — Rust Nativo (LLVM -O3)](benches/BENCHMARK_RUST.md)
- [🐍 Relatório Dedicado — Python 3.14 (CPython)](benches/BENCHMARK_PYTHON.md)
- [🦅 Relatório Dedicado — Kaz (Cranelift JIT, AOT ELF & VM)](benches/BENCHMARK_KAZ.md)

---

## 7. Como Reproduzir a Bateria Completa no Linux

```bash
# 1. Compilar o Kaz em Release Mode:
cargo build --release

# 2. Executar Kaz Cranelift JIT:
./target/release/kaz jit examples/fib_benchmark_stats.kaz

# 3. Compilar e rodar Rust Nativo (-O3):
rustc -C opt-level=3 benches/fib_native.rs -o benches/fib_native
./benches/fib_native

# 4. Executar Python 3.14:
python3 benches/fib_bench.py

# 5. Executar Kaz Bytecode VM:
./target/release/kaz run examples/fib_benchmark_stats.kaz 26

# 6. Executar as suítes de operações gerais:
rustc -C opt-level=3 benches/suite_native.rs -o benches/suite_native && ./benches/suite_native
python3 benches/suite_bench.py
./target/release/kaz jit examples/benchmark.kaz
./target/release/kaz run examples/benchmark.kaz
```
