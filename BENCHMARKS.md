# 🚀 Kaz — Relatório Oficial de Benchmarks & Verificação de Desempenho

Este documento estabelece a metodologia de benchmark oficial da linguagem **Kaz**, respondendo com rigor estatístico, resolução de microssegundos e transparência metodológica a questões da comunidade sobre otimizações de compilação, mitigação de *Constant Folding* e paridade com backends nativos (*LLVM* e *Cranelift*).

---

## 1. Ambiente de Testes & Especificações de Hardware

Todos os testes deste relatório foram executados na mesma máquina, no mesmo ambiente de hardware e sistema operacional:

- **Processador:** Genuine Intel(R) CPU @ 2.60 GHz (4 Núcleos Físicos, 8 Threads)
- **Memória RAM:** 16 GB DDR4
- **Sistema Operacional:** Microsoft Windows 11 x86_64
- **Backend Nativo Kaz:** Cranelift Code Generator (Compilado em Release Mode)
- **Compilador Rust de Referência:** `rustc 1.98.1` (LLVM Backend com `-C opt-level=3`)
- **Interpretador Python de Referência:** CPython 3.12.10

---

## 2. Refutação Matemática de *Constant Folding*

Uma das dúvidas levantadas pela comunidade foi se o tempo de `~1 ms` para `fib(26)` seria fruto de *Constant Folding* (avaliação de expressões literais em tempo de compilação sem executar a recursão em tempo de execução).

### A Prova Metodológica
Para tornar qualquer dobra de constante **fisicamente impossível**, o parâmetro `n` pode ser fornecido diretamente via argumentos de linha de comando (`argv_int(0)`), entrada de teclado / pipe padrão (`input_int()`), ou condicionado dinamicamente ao relógio do sistema:

```kaz
// Modo 1: Parâmetro vindo de argv de linha de comando
int n = argv_int(0);

// Modo 2: Parâmetro vindo do teclado ou stdin (pipe)
int n = input_int();

// Modo 3: Condicionado em runtime ao relógio
int base = (time_now_us() % 2);
int n = target_n + base - base;

int resultado = fib(n);
```

### A Prova da Complexidade Exponencial
A árvore de recursão ingênua de Fibonacci escala assintoticamente com a razão áurea:
$$O(\phi^n) \quad \text{onde} \quad \phi \approx 1.618$$

Para cada incremento de $\Delta n = 2$, o número total de chamadas de função e o tempo esperado devem crescer por um fator de:
$$\phi^2 \approx (1.61803)^2 \approx 2.618$$

Se houvesse *Constant Folding*, o tempo seria **plano ($\le 1\ \mu\text{s}$)** para qualquer $n$. Veja a progressão real observada em Kaz JIT:

| $n$ | Chamadas de Função | Tempo Esperado ($\times 2.618$) | Tempo Real Medido (Kaz JIT) | Variação Teórica |
|:---:|:---:|:---:|:---:|:---:|
| **24** | 92.693 | — | **367 $\mu$s** | Baseline |
| **26** | 242.785 | $\approx 961\ \mu\text{s}$ | **973 $\mu$s** | **+1,2%** |
| **28** | 635.621 | $\approx 2.547\ \mu\text{s}$ | **2.527 $\mu$s** | **-0,8%** |
| **30** | 1.664.079 | $\approx 6.616\ \mu\text{s}$ | **6.751 $\mu$s** | **+2,0%** |
| **32** | 4.356.521 | $\approx 17.674\ \mu\text{s}$ | **17.491 $\mu$s** | **-1,0%** |
| **34** | 11.405.039 | $\approx 45.791\ \mu\text{s}$ | **45.211 $\mu$s** | **-1,2%** |

> **Conclusão:** A correlação entre o tempo de execução medido e o crescimento assintótico teórico $O(\phi^n)$ é superior a **99%**. Toda e qualquer instrução `CALL` recursiva foi fisicamente executada pelo processador.

---

## 3. Metodologia de Medição 100% Simétrica

Para garantir **paridade científica estrita** (sem favorecimento metodológico ao Kaz e sem ruído de inicialização em linguagens interpretadas como Python ou compilação de constantes em Rust), o **mesmo protocolo experimental** foi implementado de forma idêntica em todas as 4 tecnologias testadas:

1. **Anti-Constant Folding Rigoroso:**
   - **Kaz JIT & VM:** Parâmetro $n$ derivado em runtime via clock do sistema ou recebido via linha de comando (`argv_int(0)` / `input_int()`).
   - **Rust Nativo (`-O3`):** Parâmetro $n$ passado via argumento CLI (`std::env::args()`) e isolado do compilador com `std::hint::black_box(n)`.
   - **Python 3.12:** Parâmetro $n$ recebido via argumento CLI (`sys.argv[1]`).
2. **Ciclo de Aquecimento Idêntico (Warm-up):**
   - 5 iterações completas não cronometradas antes de cada teste em todas as linguagens, aquecendo caches L1/L2 da CPU e estabilizando o *Specialized Adaptive Interpreter* (PEP 659) do Python 3.12.
3. **Amostragem Estatística Uniforme:**
   - 50 iterações cronometradas para $n = 20, 24, 26, 28$.
   - 20 iterações para $n = 30$.
   - 10 iterações para $n = 32$.
   - 5 iterações para $n = 34$.
4. **Resolução de Microssegundos ($\mu$s):**
   - **Kaz:** `time_now_us()` ancorado em contador de alta precisão monotônico.
   - **Rust:** `std::time::Instant::now().elapsed().as_micros()`.
   - **Python:** `time.perf_counter_ns() // 1000`.

---

## 4. Tabela Comparativa de Desempenho Simétrico

Abaixo estão os resultados consolidados com **Média**, **Mínimo** e **Máximo** em microssegundos ($\mu$s) para todas as tecnologias:

| $n$ | Rust Nativo (`-O3` / LLVM) | Kaz JIT (Cranelift) | Python 3.12 (CPython) | Kaz VM (Bytecode Interpreter) | Paridade Kaz JIT vs Rust -O3 | Aceleração Kaz JIT vs Python 3.12 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **20** | **28 $\mu$s** <br><sub>(27 – 56)</sub> | **53 $\mu$s** <br><sub>(53 – 60)</sub> | **1.671 $\mu$s** <br><sub>(1.646 – 1.758)</sub> | **~38.000 $\mu$s** | **1,89x** | **31,5x mais rápido** |
| **24** | **190 $\mu$s** <br><sub>(186 – 233)</sub> | **368 $\mu$s** <br><sub>(363 – 473)</sub> | **11.715 $\mu$s** <br><sub>(11.356 – 16.186)</sub> | **~268.000 $\mu$s** | **1,93x** | **31,8x mais rápido** |
| **26** | **496 $\mu$s** <br><sub>(488 – 605)</sub> | **978 $\mu$s** <br><sub>(950 – 1.306)</sub> | **31.039 $\mu$s** <br><sub>(30.161 – 38.120)</sub> | **700.147 $\mu$s** | **1,97x** | **31,7x mais rápido** |
| **28** | **1.402 $\mu$s** <br><sub>(1.279 – 1.838)</sub> | **2.583 $\mu$s** <br><sub>(2.495 – 3.212)</sub> | **80.051 $\mu$s** <br><sub>(78.297 – 92.776)</sub> | **1.879.148 $\mu$s** | **1,84x** | **31,0x mais rápido** |
| **30** | **3.355 $\mu$s** <br><sub>(mínimo)</sub> | **6.623 $\mu$s** <br><sub>(6.541 – 7.089)</sub> | **217.021 $\mu$s** <br><sub>(205.174 – 251.123)</sub> | **5.011.289 $\mu$s** | **1,97x** | **32,7x mais rápido** |
| **32** | **9.184 $\mu$s** <br><sub>(mínimo)</sub> | **17.294 $\mu$s** <br><sub>(17.185 – 17.722)</sub> | **568.552 $\mu$s** <br><sub>(541.353 – 671.256)</sub> | **13.110.141 $\mu$s** | **1,88x** | **32,8x mais rápido** |
| **34** | **23.657 $\mu$s** <br><sub>(mínimo)</sub> | **45.407 $\mu$s** <br><sub>(44.924 – 46.034)</sub> | **1.436.202 $\mu$s** <br><sub>(1.423.582 – 1.464.599)</sub> | **31.780.849 $\mu$s** | **1,91x** | **31,6x mais rápido** |

---

## 5. Análise dos Resultados

1. **Paridade com Rust Nativo (-O3):**
   O backend Cranelift do Kaz produz código de máquina que roda a uma razão extremamente estável de **~1,85x a 1,97x do binário gerado pelo LLVM em otimização máxima (`-O3`)**.
   - O LLVM gasta tempo significativo em passes exaustivos de *loop unrolling*, inlining interprocedural profundo e alocação global de registradores (adequado para compilação estática antecipada).
   - O Cranelift foi concebido especificamente para compilação JIT instantânea (tempo de compilação em sub-milissegundos), gerando assembly AMD64 enxuto e direto. Ficar a menos de 2x de distância do LLVM `-O3` é o padrão ouro para compilers JIT modernos.
2. **Comparativo com Python 3.12:**
   Mesmo com as otimizações de *Tier 2* e interpretador adaptativo da versão 3.12, o Python roda em média a **~31x a 32x mais lento** que o código nativo gerado pelo Kaz JIT.
3. **Comparativo com a VM Bytecode do Kaz:**
   O JIT nativo supera a própria máquina virtual interpretada do Kaz por uma margem de **~700x a 750x de aceleração**, confirmando a eficácia da transição para instruções de máquina direta.

---

## 6. Como Reproduzir os Testes

Todos os harnesses de benchmark estão incluídos no repositório para reprodução independente:

### 1. Teste de Caso Único via `argv` (Simetria Completa)
```bash
# Executa fib(26) com 5 warm-ups e 50 repetições nas 3 linguagens recebendo n via CLI:
.\benches\fib_native.exe 26
cargo run --release -- jit examples/fib_benchmark_stats.kaz 26
python benches/fib_bench.py 26
```

### 2. Bateria Estatística Completa ($n = 20$ a $n = 34$)

#### Kaz Cranelift JIT
```bash
cargo run --release -- jit examples/fib_benchmark_stats.kaz
```

#### Rust Nativo (LLVM -O3)
```bash
rustc -C opt-level=3 benches/fib_native.rs -o benches/fib_native.exe
.\benches\fib_native.exe
```

#### Python 3.12
```bash
python benches/fib_bench.py
```

#### Kaz VM (Bytecode Interpreter)
```bash
cargo run --release -- run examples/fib_benchmark_stats.kaz
```

### 3. Teste Dinâmico via Entrada Padrão (stdin / pipe)
```bash
echo 26 | cargo run --release -- jit examples/fib_argv_benchmark.kaz
```
