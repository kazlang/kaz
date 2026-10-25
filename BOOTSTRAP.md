# Official Reconstruction and Bootstrap Procedure (Stage Zero) 🦅

> **Freeze Date:** October 25, 2026  
> **Anchor Version:** 1.5.0 (`v1.5.0-bootstrap-anchor`)  
> **Guarantee:** Deterministic procedure to reconstruct the Kaz language from absolute scratch.  
> **Portuguese Version:** [BOOTSTRAP.pt-BR.md](BOOTSTRAP.pt-BR.md)

---

## 1. Web of Trust Topology

The compilation pipeline of the Kaz programming language operates across four chained stages:

1. **Stage 0 (Host Rust Compiler)**:
   - Native executable built directly from the Rust source code (`src/`).
   - Reference binary: `bootstrap/stage0/kaz_rust_stage0`.
2. **Stage 1 (Self-Hosted Compiler Bytecode `.kzc`)**:
   - Produced by Stage 0 compiling the pure Kaz codebase (`compiler/main.kaz`).
   - Reference artifact: `bootstrap/stage0/kazc_stage1.kzc`.
3. **Stage 2 (Autonomous x86-64 Native AOT Compiler)**:
   - Produced by Stage 0 compiling `compiler/main.kaz` to NASM assembly and linked with GNU `ld`.
   - Reference binary: `bootstrap/stage0/kazc_stage2_bin`.
4. **Stages 3 & 4 (Sovereign AOT Fixed Point)**:
   - `kazc_stage2_bin` compiles `compiler/main.kaz` emitting `kazc_stage3.asm`.
   - `kazc_stage3` compiles `compiler/main.kaz` emitting `kazc_stage4.asm`.
   - `diff -u kazc_stage3.asm kazc_stage4.asm` is formally empty (Fixed Point achieved).

---

## 2. Official Cryptographic Hashes (SHA-256)

Refer to `bootstrap/stage0/SHA256SUMS` for strict integrity validation:

- `kaz_rust_stage0`: `cbdcf3abf7ac98653943d3404ded2a664df93ecdf4bae22ea40b790f48cbb2c0`
- `kazc_stage1.kzc`: `65f3a0f6062056965855182534caca6bb8f82246c968a68686aeb4a2eb87ae5c`
- `kazc_stage2_bin`: `573dfd25e51f1e28b36460dbaeaf811d85cb66ccfe6491386e823866af9a414f`

---

## 3. Step-by-Step Instructions to Rebuild from Absolute Scratch

If all binaries are lost and only source code remains:

```bash
# 1. Compile the Host Rust Compiler (Stage 0)
cargo build --release -j 2

# 2. Generate the self-hosted compiler bytecode (Stage 1)
./target/release/kaz compile compiler/main.kaz -o kazc.kzc

# 3. Generate the native AOT compiler binary (Stage 2)
./target/release/kaz build compiler/main.kaz -o kazc_stage2

# 4. Perform self-bootstrap for Stage 3 and Stage 4
./kazc_stage2 compiler/main.kaz kazc_stage3.asm
nasm -f elf64 kazc_stage3.asm -o kazc_stage3.o
ld kazc_stage3.o -o kazc_stage3

./kazc_stage3 compiler/main.kaz kazc_stage4.asm

# 5. Verify Fixed Point
diff -u kazc_stage3.asm kazc_stage4.asm
# Output must be empty (identical SHA-256)
```
