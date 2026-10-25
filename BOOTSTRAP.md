# Procedimento Oficial de Reconstrução e Bootstrap (Estágio Zero) 🦅

> **Data de Congelamento:** 25 de Outubro de 2026  
> **Versão Âncora:** 1.5.0 (`v1.5.0-bootstrap-anchor`)  
> **Garantia:** Procedimento determinístico para reconstruir a linguagem Kaz do zero absoluto.

---

## 1. Topologia da Cadeia de Confiança

A cadeia de compilação da linguagem Kaz opera em quatro estágios encadeados:

1. **Estágio 0 (Host Rust Compiler)**:
   - Binário compilado a partir do código-fonte em Rust (`src/`).
   - Binário de referência: `bootstrap/stage0/kaz_rust_stage0`.
2. **Estágio 1 (Bytecode `.kzc` do Compilador Self-Hosted)**:
   - Gerado pelo Estágio 0 compilando o código em Kaz puro (`compiler/main.kaz`).
   - Arquivo de referência: `bootstrap/stage0/kazc_stage1.kzc`.
3. **Estágio 2 (Compilador Nativo AOT Autônomo x86-64)**:
   - Gerado pelo Estágio 0 compilando `compiler/main.kaz` para assembly NASM e linkado com GNU `ld`.
   - Binário de referência: `bootstrap/stage0/kazc_stage2_bin`.
4. **Estágios 3 e 4 (Ponto Fixo AOT Soberano)**:
   - `kazc_stage2_bin` compila `compiler/main.kaz` gerando `kazc_stage3.asm`.
   - `kazc_stage3` compila `compiler/main.kaz` gerando `kazc_stage4.asm`.
   - `diff -u kazc_stage3.asm kazc_stage4.asm` é formalmente nulo (Ponto Fixo alcançado).

---

## 2. Hashes Criptográficos Oficiais (SHA-256)

Consulte `bootstrap/stage0/SHA256SUMS` para conferência estrita de integridade:

- `kaz_rust_stage0`: `cbdcf3abf7ac98653943d3404ded2a664df93ecdf4bae22ea40b790f48cbb2c0`
- `kazc_stage1.kzc`: `65f3a0f6062056965855182534caca6bb8f82246c968a68686aeb4a2eb87ae5c`
- `kazc_stage2_bin`: `573dfd25e51f1e28b36460dbaeaf811d85cb66ccfe6491386e823866af9a414f`

---

## 3. Instruções Passo a Passo para Reconstrução a Partir do Zero

Se todos os binários forem perdidos e apenas o código-fonte restar:

```bash
# 1. Compilar o compilador Rust Host (Estágio 0)
cargo build --release -j 2

# 2. Gerar o bytecode do compilador em Kaz (Estágio 1)
./target/release/kaz compile compiler/main.kaz -o kazc.kzc

# 3. Gerar o executável nativo do compilador (Estágio 2)
./target/release/kaz build compiler/main.kaz -o kazc_stage2

# 4. Executar o auto-bootstrap do Estágio 3 e Estágio 4
./kazc_stage2 compiler/main.kaz kazc_stage3.asm
nasm -f elf64 kazc_stage3.asm -o kazc_stage3.o
ld kazc_stage3.o -o kazc_stage3

./kazc_stage3 compiler/main.kaz kazc_stage4.asm

# 5. Verificar o Ponto Fixo
diff -u kazc_stage3.asm kazc_stage4.asm
# Saída deve ser vazia (SHA-256 idêntico)
```
