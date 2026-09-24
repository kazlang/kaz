# 🦅 Relatório de Benchmarks — Linguagem Kaz (JIT, AOT ELF & VM) no Linux

Este documento consolida todos os testes e métricas de desempenho da linguagem **Kaz** no ambiente Linux, cobrindo o backend nativo **Cranelift JIT**, o gerador de binários autônomos **AOT ELF (`kaz build`)** e o interpretador de **Bytecode VM**.

---

## 1. Ambiente e Tecnologias Avaliadas

- **Linguagem:** Kaz Versão 1.1.0
- **Compilador/JIT:** Cranelift Code Generator (Release Mode)
- **Compilação Estática:** `kaz build` gerando binário ELF autônomo sem dependências externas
- **Máquina Virtual:** Kaz Stack Bytecode VM (`kaz run`)
- **Hardware:** Genuine Intel(R) CPU 0000 @ 2.60 GHz (8 vCPUs / threads), 16 GB RAM
- **Kernel:** Linux 6.18.53 x86_64

---

## 2. Bateria Estatística de Fibonacci Recursivo

Comparação direta entre **Kaz Cranelift JIT** e **Kaz Bytecode VM**:

| $n$ | Repetições | Kaz Cranelift JIT (Média) | Kaz JIT (Faixa [Min – Max]) | Kaz Bytecode VM | Ganho JIT vs VM |
|:---:|:---:|:---:|:---:|:---:|:---:|
| **20** | 50 | **58 $\mu$s** | [54 $\mu$s – 76 $\mu$s] | **21.217 $\mu$s** (~21 ms) | **365x mais rápido** |
| **24** | 50 | **381 $\mu$s** | [369 $\mu$s – 442 $\mu$s] | **144.459 $\mu$s** (~144 ms) | **379x mais rápido** |
| **26** | 50 | **990 $\mu$s** | [967 $\mu$s – 1.048 $\mu$s] | **384.260 $\mu$s** (~384 ms) | **388x mais rápido** |
| **28** | 50 | **2.590 $\mu$s** | [2.537 $\mu$s – 2.661 $\mu$s] | **971.813 $\mu$s** (~971 ms) | **375x mais rápido** |
| **30** | 30 | **6.769 $\mu$s** | [6.700 $\mu$s – 6.839 $\mu$s] | **2.543.188 $\mu$s** (~2.543 ms) | **375x mais rápido** |
| **32** | 20 | **17.696 $\mu$s** | [17.578 $\mu$s – 17.889 $\mu$s] | **6.735.419 $\mu$s** (~6.735 ms) | **380x mais rápido** |
| **34** | 15 | **46.597 $\mu$s** | [46.141 $\mu$s – 47.256 $\mu$s] | **17.435.759 $\mu$s** (~17.435 ms) | **374x mais rápido** |

*Nota: O binário ELF autônomo gerado via `kaz build` registrou tempos idênticos ao modo JIT (ex: 1.002 $\mu$s em n=26).*

---

## 3. Teste Dinâmico via Linha de Comando (Argv) e Stdin

Avaliação para $n = 26$ com entrada recebida em tempo de execução:

| Modo de Execução | Fonte do Parâmetro | Tempo Medido | Status de Anti-Constant Folding |
|---|---|:---:|:---:|
| **Kaz JIT via Argv** | `argv_int(0)` via CLI | **990 $\mu$s** | Verificado (Parâmetro externo) |
| **Kaz ELF Autônomo** | `argv_int(0)` via CLI | **1.004 $\mu$s** | Verificado (Binário nativo independente) |
| **Kaz JIT via Pipe / Stdin** | `input_int()` via pipe | **1.162 $\mu$s** | Verificado (Leitura dinâmica de stream) |
| **Kaz VM via Argv** | `argv_int(0)` via CLI | **384.260 $\mu$s** | Verificado (384 ms na VM) |

---

## 4. Suíte de Performance Geral (examples/benchmark.kaz)

Medição da suíte integrada cobrindo chamadas recursivas, loops com aritmética mista e instanciação de structs:

| Sub-teste | Operação | Kaz Cranelift JIT | Kaz Bytecode VM | Ganho JIT vs VM |
|---|---|:---:|:---:|:---:|
| **Teste 1** | Recursão Profunda: `fib(26)` | **1 ms** (990 $\mu$s) | **391 ms** | **~395x** |
| **Teste 2** | Loop Aritmético: 50.000 iterações | **< 1 ms** (0 ms) | **34 ms** | **> 68x** |
| **Teste 3** | Criação & Manipulação de Structs: 10.000 instâncias | **1 ms** | **29 ms** | **~29x** |
| **TOTAL** | **Tempo Total da Suíte** | **~2 ms** | **454 ms** | **~227x mais rápido** |

---

## 5. Como Reproduzir os Testes do Kaz no Linux

```bash
# 1. Compilar o Kaz em Release Mode:
cargo build --release

# 2. Executar a bateria estatística JIT:
./target/release/kaz jit examples/fib_benchmark_stats.kaz

# 3. Gerar binário ELF autônomo e executar:
./target/release/kaz build examples/fib_benchmark_stats.kaz -o benches/fib_kaz_bin
./benches/fib_kaz_bin 26

# 4. Executar via entrada padrão (pipe):
echo 26 | ./target/release/kaz jit examples/fib_argv_benchmark.kaz

# 5. Executar suíte geral de VM e JIT:
./target/release/kaz jit examples/benchmark.kaz
./target/release/kaz run examples/benchmark.kaz
```
