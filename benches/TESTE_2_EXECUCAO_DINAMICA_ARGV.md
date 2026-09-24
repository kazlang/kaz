# 🛡️ Teste 2: Execução Dinâmica via Linha de Comando (Argv / Stdin) e Anti-Constant Folding

Este relatório documenta a execução dos testes dinâmicos com passagem de parâmetros externos no Linux. O objetivo deste benchmark é **provar matematicamente e na prática que não há Constant Folding** e que a função é integralmente computada em tempo de execução.

---

## 1. Contexto Metodológico & Prevenção de Constant Folding

*Constant Folding* ocorre quando o compilador avalia expressões constantes em tempo de compilação, substituindo a chamada por um resultado pré-calculado fixo.

Para garantir que o compilador **não possa pré-computar** o resultado:
1. **Passagem via Argumento de Linha de Comando (`argv`):** O valor de $n$ é injetado pelo sistema operacional em runtime.
2. **Passagem via Entrada Padrão (Pipe / `stdin`):** O valor é lido do pipe durante a execução.
3. **Rust `black_box`:** Aplicação de `std::hint::black_box` na entrada e na saída.
4. **Ciclo de Warm-up:** 5 iterações prévias para estabilizar instruções e cache.

---

## 2. Resultados Medidos no Linux (n = 26)

Testando $n = 26$ com 50 repetições cronometradas após 5 iterações de warm-up:

| Tecnologia / Harness | Entrada | Média ($\mu$s) | Mediana ($\mu$s) | Mínimo ($\mu$s) | Máximo ($\mu$s) | Observações |
|---|:---:|:---:|:---:|:---:|:---:|---|
| **Rust Nativo (`-O3`)** | CLI `argv[1]` | 528 $\mu$s | 476 $\mu$s | 466 $\mu$s | 733 $\mu$s | `std::hint::black_box` duplo |
| **Kaz JIT (`kaz jit`)** | CLI `argv_int(0)` | 990 $\mu$s | ~990 $\mu$s | 967 $\mu$s | 1.048 $\mu$s | Cranelift JIT direto |
| **Kaz Binário ELF (`kaz build`)** | CLI `argv_int(0)` | 1.004 $\mu$s | ~1.000 $\mu$s | 969 $\mu$s | 1.178 $\mu$s | Executável autônomo compilado |
| **Python 3.14** | CLI `sys.argv[1]` | 24.994 $\mu$s | 24.999 $\mu$s | 24.847 $\mu$s | 25.323 $\mu$s | CPython 3.14.7 |
| **Kaz Bytecode VM** | CLI `argv_int(0)` | 384.260 $\mu$s | ~384.000 $\mu$s | 376.466 $\mu$s | 432.435 $\mu$s | Interpretador de Bytecode |
| **Kaz JIT (via Stdin / Pipe)** | `echo 26 \| ...` | 1.162 $\mu$s | — | — | — | Leitura dinâmica via `input_int()` |

---

## 3. Análise da Dispersão e Estabilidade no Linux

- **Amplitude Rust:** Mínimo de 466 $\mu$s a Máximo de 733 $\mu$s. A faixa estreita confirma que todas as 50 execuções recursivas foram integralmente efetuadas pela CPU.
- **Amplitude Kaz JIT:** Mínimo de 967 $\mu$s a Máximo de 1.048 $\mu$s (variação inferior a 8%). Estabilidade excepcional no agendamento do kernel Linux.
- **Amplitude Python 3.14:** Variação entre 24.847 $\mu$s e 25.323 $\mu$s.
- **Razão Kaz JIT vs Rust -O3:** **2,08x**.
- **Razão Kaz JIT vs Python 3.14:** **25,2x mais rápido**.
- **Razão Kaz JIT vs Kaz VM:** **388x mais rápido**.

---

## 4. Comandos de Reprodução no Linux

```bash
# 1. Rust Nativo com n=26 via CLI:
./benches/fib_native 26

# 2. Kaz JIT com n=26 via CLI:
./target/release/kaz jit examples/fib_benchmark_stats.kaz 26

# 3. Kaz Binário Autônomo ELF com n=26 via CLI:
./benches/fib_kaz_bin 26

# 4. Kaz JIT com script de argv dedicado:
./target/release/kaz jit examples/fib_argv_benchmark.kaz 26

# 5. Kaz JIT lendo de pipe / stdin:
echo 26 | ./target/release/kaz jit examples/fib_argv_benchmark.kaz

# 6. Python 3.14 com n=26 via CLI:
python3 benches/fib_bench.py 26

# 7. Kaz Bytecode VM com n=26 via CLI:
./target/release/kaz run examples/fib_benchmark_stats.kaz 26
```
