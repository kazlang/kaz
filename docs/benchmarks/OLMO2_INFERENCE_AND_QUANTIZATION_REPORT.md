# Sovereign Engine Evaluation: OLMo-2-1B Native Inference, SIMD Quantization (KZQ vs GGUF), and Ground-Truth Benchmarks

**Author:** Armando Soares (`armandosds`)  
*Tooling & Experimental Assistance:* Antigravity Agent  
**Date:** November 2026  
**Audience:** AllenAI Community, Hugging Face Hub & Open Science Researchers  
**Target Architecture:** AllenAI `OLMo-2-0425-1B` (Base Sharded FP32 Weights)  
**Execution Environment:** Pure Native Runtime (`Kaz` Systems Language, x86-64 SIMD AVX2, zero Python/PyTorch/C++ runtime dependencies) evaluated side-by-side with reference **GGUF (`llama.cpp` b9562)**.

---

## 1. Executive Summary & Context: What is Kaz?

### What is Kaz?
**Kaz** is an independent, sovereign compiled systems programming language designed from scratch with its own compiler, bytecode virtual machine, native JIT compiler (Cranelift), and a standalone tensor runtime. 
- It is **not** a Python library, not a wrapper around PyTorch, ONNX, or `llama.cpp`, and does not link against libtorch or C++ runtimes.
- It features first-class systems primitives for zero-copy memory mapping (`mmap`), lock-free memory arenas, and hand-tuned x86-64 SIMD vectorization (AVX2/FMA).
- **`.kzm` (Kaz Model format)** is a zero-copy memory-mapped binary container for neural network weights and quantization headers.
- **`KZQ` (Kaz Quantization)** is a family of hardware-aligned block quantization formats designed for low-bitwidth CPU SIMD arithmetic.

In this study, we evaluate the official **AllenAI OLMo-2 1B** model running completely standalone inside **Kaz** compared side-by-side with reference **GGUF (`llama.cpp`)** under strictly controlled conditions.

Our goals are strictly empirical, transparent, and reproducible:
1. **Engine Parity Verification:** Verify token-level and output parity between Kaz FP32 and GGUF F32 using identical weights directly converted from the official safetensors.
2. **Intra-Engine Accuracy Retention:** Measure the true retention of each quantized format against its own unquantized baseline (**Kaz FP32 Baseline** for KZQ, and **GGUF F32 Baseline** for GGUF).
3. **Standardized Bitrate & Storage Accounting:** Account for full-file storage in binary mebibytes (MiB), distinguishing nominal block-level bitrates from mathematically calculated full-file bitrates (bpw).
4. **Exact Tensor Precision Disclosure:** Document the precise quantization types applied across attention, feed-forward, token embeddings, and the language modeling head (`lm_head`).
5. **Statistical Rigor & Significance:** Report 95% Wilson confidence intervals and exact McNemar paired significance tests to separate genuine quantization effects from sample noise ($N=100$).
6. **CPU Execution Throughput:** Provide verified decode throughput on commodity CPU SIMD (AVX2) on an idle machine using the standard `llama-bench` protocol (-p 0 -n 64, 5 repetitions).

---

## 2. Model Baseline Provenance & Quantization Profiles

### Official Baseline Provenance
The reference baseline was imported directly from the official AllenAI base repository:
- **Source Repository:** [allenai/OLMo-2-0425-1B](https://huggingface.co/allenai/OLMo-2-0425-1B) (Base model, not Instruct tuned).
- **Weight Shards:** Sharded IEEE-754 FP32 safetensors (`model-00001-of-00002.safetensors` + `model-00002-of-00002.safetensors`), totaling **5,939,687,552 bytes** (5,664.5 MiB).
- **Architecture:** 16 layers, `dim = 2048`, `intermediate_size = 8192`, 16 attention heads, RMSNorm with trainable weights (post-attention layernorm and post-feedforward layernorm) plus Q/K-normalization (`q_norm`, `k_norm`), SwiGLU activations, RoPE (theta = 500,000), vocabulary of 100,352 tokens. Total model parameter count: **1,484,965,888**.

### GGUF Model Provenance & Verification
Reference GGUF models were obtained and verified as follows:
- **GGUF `F32` (Exact Safetensors FP32 Equivalent):** The official `convert_hf_to_gguf.py` from `llama.cpp` requires `torch` (PyTorch) to be installed in the environment. To avoid third-party dependencies, we authored `tools/hf_to_gguf_f32.py` in pure Python standard library (`struct` and binary file offsets). It reads the IEEE-754 FP32 little-endian bytes directly from the safetensors binary segments and packs them into the GGUF container without intermediate floating-point rounding. A checksum comparison confirms that the raw byte payload of every tensor (e.g. `token_embd.weight`, 822,083,584 bytes, `SHA-256: d8ee0366d704dba055d3b74ff68dacd842e1cc83e96d3a9ddfd38012c81fbbad`) in `olmo2-1b-f32.gguf` matches the safetensors payload byte-for-byte.
- **Official GGUF Models:** Downloaded from the official AllenAI GGUF repository [allenai/OLMo-2-0425-1B-GGUF](https://huggingface.co/allenai/OLMo-2-0425-1B-GGUF), verified against Git-LFS SHA-256 pointers:
  - **GGUF `F16`:** 2,973,650,560 B (2,835.9 MiB) — *SHA-256:* `452d42f1ac5a1d1d62a6a7c4e2c6adfe4ac279f6b4ff44c9e2ea452a0d9c6df2`
  - **GGUF `Q4_K_M`:** 935,513,728 B (892.2 MiB) — *SHA-256:* `ba60879f11e0beeea54027ba1ccb9cd1485aa0d822f563cc611b48a53e227c0d`
  - **GGUF `Q4_0`:** 892,259,968 B (850.9 MiB) — *SHA-256:* `deb530d9560ef4a0306f522e07266240e39bd73bb89744c1317f4b7de7a09feb`
  - **GGUF `Q3_K_M`:** 778,980,992 B (742.9 MiB) — *SHA-256:* `e8985a478ab11ec690f8a27040539d4e6d59d6b20f6a336e2d93b10964bb9a59`

### Binary Sizes & Bitrate Accounting

All sizes are reported in binary mebibytes (**MiB**, 1 MiB = 1,048,576 bytes) alongside exact disk bytes to ensure direct correspondence with `ls -l`.  
**Full-File Bitrate** is mathematically computed across the entire binary artifact:  
$$\text{Full-File bpw} = \frac{\text{Total File Bytes} \times 8}{1,484,965,888 \text{ parameters}}$$

| Format / Profile | Model Artifact | Exact Size (Bytes) | Size in MiB | Target Block Format | Full-File bpw | Delta vs Reference GGUF `Q4_K_M` |
| :--- | :--- | ---: | :---: | :---: | :---: | :---: |
| **FP32 Reference Baseline (Kaz)** | `olmo-2-1b.kzm` | 5,939,689,920 B | 5,664.5 MiB | 32-bit float | 32.00 bpw | Baseline |
| **GGUF `F32` (Reference Baseline)** | `olmo2-1b-f32.gguf` | 5,943,217,792 B | 5,667.9 MiB | 32-bit float | 32.02 bpw | Baseline |
| **GGUF `F16` (Official Control)** | `OLMo-2-0425-1B-F16.gguf` | 2,973,650,560 B | 2,835.9 MiB | 16-bit float | 16.02 bpw | Control |
| **GGUF `Q4_K_M`** | `OLMo-2-0425-1B-Q4_K_M.gguf` | 935,513,728 B | 892.2 MiB | k-quants (4/5/6-bit mixed) | **5.04 bpw** | Reference |
| **GGUF `Q4_0`** | `OLMo-2-0425-1B-Q4_0.gguf` | 892,259,968 B | 850.9 MiB | 4-bit uniform (18B / 32w) | **4.81 bpw** | -41.3 MiB (-4.6%) |
| **Kaz `KZQ-4B` (Balanced 4-bit)** | `olmo-2-1b-kzq4.kzm` | **835,746,240 B** | **797.0 MiB** | 4-bit BF16 scale (18B / 32w) | **4.50 bpw** | **-95.2 MiB (-10.7%)** |
| **GGUF `Q3_K_M`** | `OLMo-2-0425-1B-Q3_K_M.gguf` | 778,980,992 B | 742.9 MiB | k-quants (3/4/5-bit mixed) | **4.20 bpw** | -149.3 MiB (-16.7%) |
| **Kaz `KZQ-4M` (Refined Profile)** | `olmo-2-1b-kzq37.kzm` | **768,637,376 B** | **733.0 MiB** | 4-bit Attn/Down + 3-bit FFN | **4.14 bpw** | **-159.2 MiB (-17.8%)** |
| **Kaz `KZQ-4S` (Smart Hybrid)** | `olmo-2-1b-kzq4s.kzm` | **683,702,720 B** | **652.0 MiB** | 4-bit Attn + 3-bit MSE FFN/Vocab | **3.68 bpw** | **-240.2 MiB (-26.9%)** |

### Tensor Precision Breakdown: Embeddings and Output Head
- `KZQ-4B` quantizes **all** weight tensors, including `token_embd` and `lm_head`, to 4-bit (18 bytes per 32 weights with BF16 scales).
- Reference GGUF files preserve `output.weight` at higher precision (`Q6_K` in `Q4_K_M`, `Q4_0`, and `Q3_K_M`).

| Profile / File | Attention Projections (`q/k/v/o`) | Feed-Forward Projections (`gate/up/down`) | Token Embeddings (`token_embd`) | Output Head (`output.weight` / `lm_head`) |
| :--- | :---: | :---: | :---: | :---: |
| **Kaz FP32 Reference** | FP32 | FP32 | FP32 | FP32 |
| **GGUF F32 Reference** | F32 | F32 | F32 | F32 |
| **GGUF F16 Control** | F16 | F16 | F16 | F16 |
| **GGUF `Q4_K_M`** | Q4_K | Q4_K (`gate/up`) / Q6_K (`down`) | Q4_K | **Q6_K** |
| **GGUF `Q4_0`** | Q4_0 | Q4_0 | Q4_0 | **Q6_K** |
| **Kaz `KZQ-4B`** | KZQ-4B (4-bit) | KZQ-4B (4-bit) | **KZQ-4B (4-bit)** | **KZQ-4B (4-bit)** |
| **Kaz `KZQ-4M`** | KZQ-4B (4-bit) | KZQ-3B (`gate/up`) / KZQ-4B (`down`) | **KZQ-4B (4-bit)** | **KZQ-4B (4-bit)** |
| **GGUF `Q3_K_M`** | Q3_K | Q3_K (`gate/up`) / Q5_K (`down`) | Q3_K | **Q6_K** |
| **Kaz `KZQ-4S`** | KZQ-4B (4-bit) | KZQ-3B MSE | **KZQ-3B MSE** | **KZQ-3B MSE** |

---

## 3. Head-to-Head 100-Question Ground-Truth Benchmark

### Rigorous Evaluation Protocol
All 9 models were evaluated under identical frozen test harnesses without manual intervention:
- **Decoding Protocol:** Deterministic greedy decoding ($T = 0.0$), sequence length limit $n = 32$.
- **Prompt Template:** Exact literal string `Question: <prompt>\nAnswer:`
- **Tokenizer Parity Gate (Passed):** Both engines underwent strict input token verification. `llama-tokenize` and `kaz` native tokenizer produced **100% identical token ID streams** across all 100 test prompts (`SHA-256: 3a57d7b7c59eac802c8284db3c5bb8d8e702f0b8e51d9e484beccf95e70ea780`).
- **Frozen Evaluator (`score.py` & `score.kaz`):** The scorer strips prompt echos from the start of the completion, evaluates only the first answer line, and enforces word-boundary regex matching (`\b` / `(?<!\w)`) on numerical and short answers to block false-positive substring matches (e.g. `3.33` or `1913`). Both scorers pass 19/19 self-tests and score 100% identically across all model outputs.

### Benchmark Results & Intra-Engine Retention

To avoid confounding quantization degradation with inter-engine runtime differences, **Accuracy Retention** is calculated strictly within each engine's own unquantized baseline (**GGUF F32** for GGUF formats, and **Kaz FP32** for Kaz formats):

| Runtime / Engine | Format / Profile | Model Artifact | Size (MiB) | 100-Q Score | Accuracy (%) | 95% Wilson CI | Intra-Engine Retention |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **llama.cpp** | **GGUF `F32`** | `olmo2-1b-f32.gguf` | 5,667.9 MiB | **53 / 100** | **53.0%** | [43.3% – 62.5%] | **100.0%** (GGUF Baseline) |
| **llama.cpp** | **GGUF `F16`** | `OLMo-2-0425-1B-F16.gguf` | 2,835.9 MiB | **52 / 100** | **52.0%** | [42.3% – 61.5%] | **98.1%** (52 / 53) |
| **llama.cpp** | **GGUF `Q4_K_M`** | `OLMo-2-0425-1B-Q4_K_M.gguf` | 892.2 MiB | **52 / 100** | **52.0%** | [42.3% – 61.5%] | **98.1%** (52 / 53) |
| **llama.cpp** | **GGUF `Q4_0`** | `OLMo-2-0425-1B-Q4_0.gguf` | 850.9 MiB | **45 / 100** | **45.0%** | [35.6% – 54.8%] | **84.9%** (45 / 53) |
| **llama.cpp** | **GGUF `Q3_K_M`** | `OLMo-2-0425-1B-Q3_K_M.gguf` | 742.9 MiB | **43 / 100** | **43.0%** | [33.7% – 52.8%] | **81.1%** (43 / 53) |
| **Kaz Runtime** | **Kaz `FP32`** | `olmo-2-1b.kzm` | 5,664.5 MiB | **53 / 100** | **53.0%** | [43.3% – 62.5%] | **100.0%** (Kaz Baseline) |
| **Kaz Runtime** | **Kaz `KZQ-4B`** | `olmo-2-1b-kzq4.kzm` | **797.0 MiB** | **43 / 100** | **43.0%** | [33.7% – 52.8%] | **81.1%** (43 / 53) |
| **Kaz Runtime** | **Kaz `KZQ-4M`** | `olmo-2-1b-kzq37.kzm` | **733.0 MiB** | **35 / 100** | **35.0%** | [26.4% – 44.7%] | **66.0%** (35 / 53) |
| **Kaz Runtime** | **Kaz `KZQ-4S`** | `olmo-2-1b-kzq4s.kzm` | **652.0 MiB** | **29 / 100** | **29.0%** | [21.0% – 38.5%] | **54.7%** (29 / 53) |

---

## 4. Analysis and Discussion

### A. Engine Concordance: Kaz FP32 vs GGUF F32
Following the tokenizer regex alignment (matching GPT-4/OLMo-2 BPE specifications), question-by-question comparison between **Kaz FP32** and **GGUF F32** showed:
- **Input Token IDs:** 100 / 100 identical ID sequences (`SHA-256: 3a57d7b7c59eac802c8284db3c5bb8d8e702f0b8e51d9e484beccf95e70ea780`).
- **First-Line Completion Agreement:** 100 / 100 identical first generated lines.
- **Full Sequence Completion Agreement:** 98 / 100 identical 32-token string completions (excluding trailing newlines and `[end of text]` tokens). The only two divergent tails were Q16 and Q67, where after generating multiple newlines and next invented questions, accumulated floating-point rounding caused minor tail branching.
- **Scored Correctness Concordance:** Both correct: 53 | Both incorrect: 47 | Discordant pairs: $b = 0, c = 0$.
- **Exact McNemar Two-Sided Test:** $p = 1.000$.

All 23 divergences observed in earlier preliminary runs were definitively identified as artifacts of a character-by-character BPE tokenizer that lacked regex splitting for alphanumeric boundaries (e.g. `H2O`, `CO2`, `1010`). With the correct regex pattern implemented in Kaz stdlib, the Kaz tensor engine matches `llama.cpp` token ID by token ID and produces identical first-line answers.

### B. Statistical Significance & Paired Tests ($N = 100$)
Paired exact McNemar tests evaluate the relationship between Kaz's balanced 4-bit format (**KZQ-4B**, 797 MiB) and standard GGUF formats:
- **`KZQ-4B` vs. `GGUF Q3_K_M` (743 MiB):**  
  - Both correct: 37 | Only KZQ-4B: 6 | Only Q3_K_M: 6 | Both wrong: 51  
  - **Exact McNemar $p = 1.000$ ($b = 6, c = 6$).**  
  The accuracy between KZQ-4B and Q3_K_M is identical (43% vs 43%), with zero discordant bias.
- **`KZQ-4B` vs. `GGUF Q4_0` (851 MiB):**  
  - Both correct: 41 | Only KZQ-4B: 2 | Only Q4_0: 4 | Both wrong: 53  
  - **Exact McNemar $p = 0.688$ ($b = 2, c = 4$).**  
  There is no statistically significant difference between KZQ-4B and Q4_0 ($p > 0.05$).
- **`KZQ-4B` vs. `GGUF Q4_K_M` (892 MiB):**  
  - Both correct: 41 | Only KZQ-4B: 2 | Only Q4_K_M: 11 | Both wrong: 46  
  - **Exact McNemar $p = 0.022$ ($b = 2, c = 11$).**  
  *Multiple testing note:* With 3 pairwise comparisons against GGUF formats, a standard Bonferroni correction sets the significance threshold at $\alpha = 0.05 / 3 \approx 0.0167$. Under this threshold, the uncorrected $p = 0.022$ is marginally above the significance boundary, though `Q4_K_M` remains noticeably stronger in practice while requiring +95.2 MiB (+11.9%) more storage.

### C. Size-Accuracy Relationship & Immediate Future Work
Evaluating retention strictly within each engine's baseline shows the practical tradeoffs:
- **`Q4_K_M` (892 MiB):** 98.1% retention
- **`Q4_0` (851 MiB):** 84.9% retention
- **`KZQ-4B` (797 MiB):** 81.1% retention (4.50 bpw)
- **`Q3_K_M` (743 MiB):** 81.1% retention (4.20 bpw)
- **`KZQ-4M` (733 MiB):** 66.0% retention (4.14 bpw)
- **`KZQ-4S` (652 MiB):** 54.7% retention (3.68 bpw)

`KZQ-4B` lands in the same general size-accuracy range as `Q4_0` and `Q3_K_M`. However, with `Q3_K_M` achieving the exact same accuracy (43/100) while being 54.1 MiB smaller (742.9 vs 797.0 MiB), `KZQ-4B` does not define a new Pareto optimum; rather, it sits within the expected statistical noise band of mature 3-bit / 4-bit quantizations. Meanwhile, `Q4_K_M` is noticeably better at +95.2 MiB.

> **Immediate Future Work (Ablation & Perplexity):**  
> We hypothesize that `Q4_K_M`'s higher retention is bolstered by preserving `output.weight` at 6-bit (`Q6_K`) and using mixed-bit intermediate projections. To verify this hypothesis empirically, a formal ablation quantizing an all-4-bit `Q4_0` baseline (with 4-bit embeddings and 4-bit output head matching `KZQ-4B`'s uniform recipe) is scheduled as immediate future work. Furthermore, continuous evaluation via Kullback-Leibler Divergence (KLD) and perplexity (PPL) on WikiText-2 (100 blocks of 512 tokens) will provide metric resolution independent of prompt substring heuristics.

---

## 5. CPU Execution Environment & Pure Decode Throughput

### Hardware Specifications
- **CPU Model:** `Genuine Intel(R) CPU 0000 @ 2.60GHz` (Haswell microarchitecture, 1 socket, 4 physical cores, 8 logical threads).
- **SIMD Features:** AVX2, FMA, BMI2.
- **Host RAM:** 16 GB DDR3 (dual-channel, memory streaming saturation ceiling at **15.5 GB/s decimal** verified via `bw.c`).
- **Governor:** `performance` across all physical cores.

### Pure Decode Throughput Benchmark Protocol
To isolate pure autoregressive decode throughput from prompt-processing overhead, the official `llama-bench` protocol (`-p 0 -n 64`, 5 repetitions, mean ± std) was applied across both engines under thread allocations of $t=4$ (physical cores) and $t=8$ (SMT logical threads):

| Runtime / Engine | Format / Profile | Model Size | Decode Speed ($t=4$) | Decode Speed ($t=8$) | Effective Bandwidth ($t=4$) [GB/s] |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **llama.cpp** | **GGUF F32** | 5,667.9 MiB | **2.41 ± 0.04 tok/s** | 1.38 ± 0.09 tok/s | ~14.3 GB/s |
| **Kaz Runtime** | **Kaz FP32** | 5,664.5 MiB | **2.40 ± 0.04 tok/s** | 2.44 ± 0.02 tok/s | ~14.3 GB/s |
| **llama.cpp** | **GGUF F16** | 2,835.9 MiB | **4.67 ± 0.04 tok/s** | 2.26 ± 0.06 tok/s | ~13.9 GB/s |
| **llama.cpp** | **GGUF Q4_K_M** | 892.2 MiB | **13.91 ± 0.11 tok/s** | 3.61 ± 0.90 tok/s | ~13.0 GB/s |
| **llama.cpp** | **GGUF Q4_0** | 850.9 MiB | **14.20 ± 0.95 tok/s** | 4.71 ± 0.77 tok/s | ~12.7 GB/s |
| **llama.cpp** | **GGUF Q3_K_M** | 742.9 MiB | **16.03 ± 0.29 tok/s** | 5.33 ± 1.67 tok/s | ~12.5 GB/s |
| **Kaz Runtime** | **Kaz KZQ-4B** | 797.0 MiB | **9.09 ± 0.19 tok/s** | 9.93 ± 0.78 tok/s | ~7.6 GB/s |
| **Kaz Runtime** | **Kaz KZQ-4M** | 733.0 MiB | **6.35 ± 0.10 tok/s** | 7.73 ± 0.25 tok/s | ~4.9 GB/s |
| **Kaz Runtime** | **Kaz KZQ-4S** | 652.0 MiB | **4.78 ± 0.20 tok/s** | 5.60 ± 0.31 tok/s | ~3.3 GB/s |

### Performance Analysis & Optimization Roadmap
1. **Thread Pool Architecture & Scaling:**
   - In earlier preliminary runs, Kaz throughput dropped under 8 threads (from 9.15 down to 5.48 tok/s) due to spinlock contention and sleep-mutex wake-up overhead in the custom thread pool. In commit `54dd797`, the SIMD worker pool was redesigned using standard POSIX/futex `std::sync::Barrier`, eliminating spinlock collapse and enabling throughput to scale stably to 9.93 tok/s under $t=8$.
2. **SMT Scaling Behavior in `llama.cpp`:**
   - In `llama.cpp`, expanding from 4 physical cores to 8 logical threads causes throughput regressions of 50% to 75% across all formats (e.g. `Q4_K_M` drops from 13.91 to 3.61 tok/s). Because `bw.c` verifies that this host achieves 15.5 GB/s throughput under 8 threads, the SMT regression is driven by thread synchronization overhead and spin-lock contention when hyperthreads share execution units, rather than memory bus exhaustion.
3. **Session-to-Session Variance in `llama.cpp`:**
   - Across separate benchmark runs on the same hardware, `llama.cpp` decode throughput displayed ~15% session variance (e.g. `Q4_K_M` reached 16.69 tok/s in earlier runs vs. 13.91 tok/s in this run under performance governor and 5 repetitions). The reported values reflect the fully automated run with zero background processes.
4. **Bandwidth Headroom & Optimization Path:**
   - The host saturation ceiling measured by `bw.c` is 15.5 GB/s decimal ($10^9$ B/s). For `KZQ-4B` at 9.09 tok/s, streaming 835.7 MB per second yields **~7.6 GB/s decimal**, utilizing ~49% of the host bus bandwidth. Closing this ~1.5x gap to `llama.cpp` defines an immediate technical roadmap: cache-tiled matrix-vector kernels, unrolling BF16 scale conversions, and fusing sub-byte unpacking in AVX2.
5. **Execution Scope (Pure CPU SIMD):**
   - All tests in this report represent pure CPU execution. GPU acceleration (Vulkan/CUDA) is explicitly on the project roadmap, alongside native display server integration within KazOS.

---

## 6. Author's Projects & Related Work

This research is conducted as an open-science initiative by Armando Soares:
- **Kaz Language:** [kazlang.xyz](https://kazlang.xyz) — statically-typed compiled systems language with custom bytecode VM, native Cranelift JIT, AOT machine code compilation, zero-copy memory mapping, and integrated SIMD AI tensor runtime.
- **Neuronal:** [neuronal.ia.br](https://neuronal.ia.br) — research and machine learning models for Portuguese / multilingual NLP, open datasets, and sovereign model evaluations.
- **Architect:** [architect.neuronal.ia.br](https://architect.neuronal.ia.br) — local desktop application and studio for offline inference, block quantization, and native agentic workflows with zero external dependencies.
- **Linux Nux:** custom lightweight Linux distribution tuned for native development and containerless microservices.
- **Lumina IDE:** [github.com/lumina-ide](https://github.com/lumina-ide) — modern, open-source, AI-powered code editor built on top of VS Code, designed and maintained by Neuronal AI.
- **Fapybara Browser:** [fapybara.download](https://fapybara.download) — Gecko-powered sovereign browser experiment built for privacy, performance, and upcoming on-device Kaz AI integration.

---

## 7. Reproduction Protocol & Automated Harness

All results in this report were generated automatically via the frozen reproduction harness:

```bash
# 1. Environment & Hashes Check
./run_all.sh env

# 2. Safetensors FP32 -> GGUF F32 Conversion (Pure Python stdlib, zero PyTorch)
./run_all.sh convert

# 3. Input Token & First Token Parity Gate
./run_all.sh parity

# 4. 100-Question QA Suite (Frozen Scorer)
./run_all.sh qa

# 5. Speed Benchmarks (llama-bench & bench_speed.kaz: -p 0 -n 64, 5 reps)
./run_all.sh speed

# 6. Automatic Table Generation & Paired McNemar Tests
./run_all.sh report
```

---
*Kaz Systems Initiative — Sovereign Native Systems Architecture.*
