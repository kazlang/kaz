# 📊 Teste 1: Bateria Estatística Completa de Fibonacci (n = 20 a 34) — Linux x86_64

Este relatório detalha a reprodução e os resultados da **Bateria Estatística Completa de Fibonacci** executada no ambiente Linux, comparando **Rust Nativo (LLVM -O3)**, **Kaz Cranelift JIT**, **Python 3.14** e a **Kaz Bytecode VM**.

---

## 1. Especificações do Ambiente de Teste (Linux)

- **Processador:** Genuine Intel(R) CPU 0000 @ 2.60 GHz (4 Núcleos Físicos, 8 Threads)
- **Memória RAM:** 16 GB DDR4 (Linux kernel 6.18.53 x86_64)
- **Sistema Operacional:** Linux GNU/Linux
- **Kaz:** Versão 1.1.0 (Backend Cranelift Release Mode & Stack Bytecode VM)
- **Rust:** `rustc 1.98.1` (`-C opt-level=3`, LLVM backend)
- **Python:** CPython 3.14.7

---

## 2. Metodologia Experimental

1. **Warm-up Padronizado:** 5 iterações completas não cronometradas antes de cada medição em todas as linguagens para aquecer caches L1/L2 e estabilizar o interpretador adaptativo.
2. **Mitigação de Otimizações Espúrias:**
   - **Rust:** `std::hint::black_box` aplicado tanto à entrada quanto ao retorno da função para prevenir *Loop-Invariant Code Motion* (LICM) e *Constant Folding*.
   - **Kaz JIT:** Parâmetro `n` derivado dinamicamente com base no clock (`time_now_us() % 2`) para forçar avaliação em runtime.
   - **Python:** Avaliação repetida com medição individual via `time.perf_counter_ns()`.
3. **Métricas Apuradas:** Média aritmética, Mediana estatística, valor Mínimo e Máximo em microssegundos ($\mu$s).
4. **Amostragem:**
   - $n = 20, 24, 26, 28$: 50 repetições
   - $n = 30$: 30 repetições (Python: 20)
   - $n = 32$: 20 repetições (Python: 10)
   - $n = 34$: 15 repetições (Python: 10)

---

## 3. Tabela de Resultados Consolidados (Linux)

Todos os tempos expressos em microssegundos ($\mu$s):

| $n$ | Rust Nativo (-O3) | Kaz Cranelift JIT | Python 3.14 | Kaz Bytecode VM | Razão Kaz JIT / Rust (Mediana) | Aceleração Kaz JIT vs Python 3.14 | Aceleração Kaz JIT vs Kaz VM |
|:---:|---|---|---|---|:---:|:---:|:---:|
| **20** | **37 $\mu$s** (Méd: 40, [33 – 54]) | **58 $\mu$s** (Min: 54, Max: 76) | **1.798 $\mu$s** (Méd: 1.971, [1.352 – 4.199]) | **21.217 $\mu$s** (Min: 20.320, Max: 22.067) | **1,56x** | **31,0x mais rápido** | **365x mais rápido** |
| **24** | **178 $\mu$s** (Méd: 208, [178 – 319]) | **381 $\mu$s** (Min: 369, Max: 442) | **9.480 $\mu$s** (Méd: 9.491, [9.263 – 10.068]) | **144.459 $\mu$s** (Min: 140.717, Max: 147.657) | **2,14x** | **24,9x mais rápido** | **379x mais rápido** |
| **26** | **470 $\mu$s** (Méd: 508, [466 – 766]) | **990 $\mu$s** (Min: 967, Max: 1.048) | **24.668 $\mu$s** (Méd: 24.657, [24.511 – 24.983]) | **384.260 $\mu$s** (Min: 376.466, Max: 432.435) | **2,10x** | **24,9x mais rápido** | **388x mais rápido** |
| **28** | **1.235 $\mu$s** (Méd: 1.343, [1.225 – 2.013]) | **2.590 $\mu$s** (Min: 2.537, Max: 2.661) | **64.554 $\mu$s** (Méd: 64.718, [64.067 – 68.003]) | **971.813 $\mu$s** (~971 ms) | **2,09x** | **24,9x mais rápido** | **375x mais rápido** |
| **30** | **3.218 $\mu$s** (Méd: 3.231, [3.208 – 3.394]) | **6.769 $\mu$s** (Min: 6.700, Max: 6.839) | **170.425 $\mu$s** (Méd: 170.392, [169.563 – 171.669]) | **2.543.188 $\mu$s** (~2.543 ms) | **2,10x** | **25,1x mais rápido** | **375x mais rápido** |
| **32** | **8.511 $\mu$s** (Méd: 8.496, [8.416 – 8.576]) | **17.696 $\mu$s** (Min: 17.578, Max: 17.889) | **444.811 $\mu$s** (Méd: 447.920, [440.274 – 469.389]) | **6.735.419 $\mu$s** (~6.735 ms) | **2,08x** | **25,1x mais rápido** | **380x mais rápido** |
| **34** | **22.055 $\mu$s** (Méd: 22.056, [22.037 – 22.092]) | **46.597 $\mu$s** (Min: 46.141, Max: 47.256) | **1.158.003 $\mu$s** (Méd: 1.157.695, [1.148.394 – 1.168.691]) | **17.435.759 $\mu$s** (~17.435 ms) | **2,11x** | **24,8x mais rápido** | **374x mais rápido** |

---

## 4. Análise dos Resultados no Linux

1. **Paridade com Rust Nativo (-O3):**
   - O backend Cranelift do Kaz mantém uma proporção praticamente fixa de **~2,08x a 2,14x** em relação ao Rust compilado pelo LLVM com otimizações máximas (`-O3`).
   - Essa paridade é considerada excelente para compiladores JIT, dado que o Cranelift prioriza compilação instantânea (sub-milissegundos) em vez dos passes caros de otimização global do LLVM.
2. **Comparativo com Python 3.14:**
   - O Kaz JIT supera o Python 3.14 por um fator consistente de **~25x mais rápido** em todas as faixas de teste.
   - Mesmo com as melhorias de performance do CPython 3.14 em Linux, o código de máquina nativo gerado pelo Kaz processa chamadas recursivas diretamente na pilha da CPU sem overhead de despacho de interpretador.
3. **Comparativo com a Kaz Bytecode VM:**
   - A Kaz VM no Linux é cerca de **1,8x mais rápida** do que no Windows (fib(26) caiu de 700 ms para 384 ms).
   - O Kaz JIT supera a Kaz VM por **~375x a 390x**, demonstrando o ganho da compilação JIT direta para AMD64.

---

## 5. Como Reproduzir Este Teste no Linux

```bash
# 1. Compilar e rodar Rust Nativo:
rustc -C opt-level=3 benches/fib_native.rs -o benches/fib_native
./benches/fib_native

# 2. Executar Kaz Cranelift JIT:
./target/release/kaz jit examples/fib_benchmark_stats.kaz

# 3. Executar Kaz Binário Autônomo ELF (gerado com 'kaz build'):
./target/release/kaz build examples/fib_benchmark_stats.kaz -o benches/fib_kaz_bin
./benches/fib_kaz_bin

# 4. Executar Python 3.14:
python3 benches/fib_bench.py

# 5. Executar Kaz Bytecode VM:
./target/release/kaz run examples/fib_benchmark_stats.kaz 26
```
