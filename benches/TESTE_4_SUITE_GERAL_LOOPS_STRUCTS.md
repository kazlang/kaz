# ⚡ Teste 4: Suíte Sintética de Performance — Recursão, Loops e Structs (Linux)

Este relatório analisa os resultados da **Suíte Geral de Benchmarks** (`examples/benchmark.kaz`), testada de forma rigorosamente equivalente em **Rust Nativo (LLVM -O3)**, **Kaz Cranelift JIT**, **Python 3.14** e **Kaz Bytecode VM** no Linux.

---

## 1. Descrição dos Componentes da Suíte

1. **Recursão Profunda de CallFrames — Fibonacci(26):**
   Mede a eficiência de despacho de chamadas de função, criação/destruição de frames de pilha e retorno de inteiros.
2. **Loop Aritmético e Dispatch de Opcodes (50.000 iterações):**
   Executa 50.000 voltas acumulando operações com inteiros e ponto flutuante:
   $$\text{acumulador} += (i \times 1.5) - (i / 2.0)$$
   Resultado esperado: `1250025000.0`.
3. **Criação e Manipulação de Structs / Objetos (10.000 instâncias):**
   Instancia 10.000 objetos `Ponto3D { x, y, z }` e calcula a distância euclidiana acumulada via raiz quadrada:
   $$\sum_{j=1}^{10000} \sqrt{(j \cdot 1.0)^2 + (j \cdot 2.0)^2 + (j \cdot 3.0)^2} = \sum_{j=1}^{10000} j \sqrt{14} \approx 187101577{,}6256$$
   Mede alocação, acesso a campos de estruturas e chamadas à biblioteca padrão matemática.

---

## 2. Resultados Consolidados no Linux

| Sub-teste / Operação | Rust Nativo (-O3) | Kaz Cranelift JIT | Python 3.14 | Kaz Bytecode VM | Aceleração Kaz JIT vs Python | Aceleração Kaz JIT vs Kaz VM |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| **1. Recursão (Fibonacci 26)** | **0,516 ms** (515 $\mu$s) | **0,990 ms** (990 $\mu$s) | **25,01 ms** (25.007 $\mu$s) | **391 ms** | **25,3x mais rápido** | **395x mais rápido** |
| **2. Loop Aritmético (50k ops)** | **0,102 ms** (101 $\mu$s) | **< 0,5 ms** (~0 ms) | **6,24 ms** (6.240 $\mu$s) | **34 ms** | **> 12x mais rápido** | **> 68x mais rápido** |
| **3. Structs & Heap (10k instâncias)** | **0,058 ms** (57 $\mu$s) | **~1,0 ms** (~1.000 $\mu$s) | **6,33 ms** (6.331 $\mu$s) | **29 ms** | **6,3x mais rápido** | **29x mais rápido** |
| **TEMPO TOTAL DA SUÍTE** | **0,675 ms** | **~2,0 ms** | **37,58 ms** | **454 ms** | **~18,8x mais rápido** | **~227x mais rápido** |

---

## 3. Análise Detalhada dos Resultados

1. **Eficiência do JIT em Loops e Aritmética:**
   - No teste de loop aritmético de 50k iterações, o Kaz JIT executa a sequência em tempo imperceptível (< 1 ms), gerando instruções diretas de registradores XMM para a FPU do processador AMD64.
2. **Manipulação de Structs:**
   - O Kaz JIT instancia e calcula distâncias para 10.000 structs em cerca de 1 milissegundo, superando a implementação orientada a objetos com `__slots__` do Python 3.14 por **6,3x**.
   - O Rust em `-O3` é ultrarrápido (58 $\mu$s) devido à capacidade do LLVM de otimizar a representação em memória contígua e vetorizar operações com instruções AVX/SSE.
3. **Desempenho Geral Consolidado:**
   - Para toda a suíte somada, o Kaz JIT completa em **~2 ms**, enquanto o Python 3.14 leva **37,58 ms** (~18,8x mais lento) e a Kaz VM interpretada leva **454 ms** (~227x mais lenta).

---

## 4. Como Reproduzir Este Teste no Linux

```bash
# 1. Executar no Kaz Cranelift JIT:
./target/release/kaz jit examples/benchmark.kaz

# 2. Executar na Kaz Bytecode VM:
./target/release/kaz run examples/benchmark.kaz

# 3. Executar em Rust Nativo (-O3):
rustc -C opt-level=3 benches/suite_native.rs -o benches/suite_native
./benches/suite_native

# 4. Executar em Python 3.14:
python3 benches/suite_bench.py
```
