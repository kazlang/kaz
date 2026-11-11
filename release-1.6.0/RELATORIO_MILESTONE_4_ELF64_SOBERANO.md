# Relatório Técnico - Milestone 4: Backend Nativo ELF64 Soberano & Kaz 1.6.0 🦅

**Data:** 9 de Novembro de 2026  
**Autor:** Armando Soares  
**Status:** Concluído com Sucesso

---

## 1. Visão Geral do Marco Soberano

O lançamento do **Kaz 1.6.0** marca a transição histórica do ecossistema Kaz para o **Self-Hosting Soberano**. O compilador ganha a capacidade de emitir binários executáveis Linux x86-64 no formato padrão `ELF64 ET_EXEC` diretamente a partir da AST/Scalar IR em memória, **sem depender de montadores externos (NASM), transpiladores C (GCC/Clang) ou bibliotecas de sistema C (`libc`)**.

```text
Código Kaz (.kaz)
       │
       ▼
Análise Léxica & Sintática (Pratt Parser puro)
       │
       ▼
Árvore Sintática Abstrata (Kaz AST)
       │
       ▼
Scalar IR Lowering (sast_lower_expr & native calls)
       │
       ▼
Codificador x86-64 Nativo (REX, ModR/M, SIB, LEA, Jcc, SYSCALL)
       │
       ▼
Imagem Nativa & Tabela de Relocações (.text, .rodata, .data)
       │
       ▼
Bootstrap Soberano (_start com argc/argv direto da pilha)
       │
       ▼
Executável ELF64 Standalone (e_entry direto no Kernel Linux)
```

---

## 2. Inovações Arquiteturais do Kaz 1.6.0

1. **Backend ELF64 Soberano (`compiler/backend/elf64/`):**
   - Emissão de cabeçalhos ELF64 de 64 bytes e Program Headers `PT_LOAD` com paginação alinhada a 4096 bytes (páginas R+X, R e RW).
   - Bootstrap `_start` autônomo: captura `argc` e `argv` diretamente do topo da pilha do processo (`[rsp]`, `rsp+8`), invoca `Main()` e encerra o processo via syscall 60 (`sys_exit`) com o código de retorno em `rdi`.
   - Zero dependência de libc e zero ferramentas externas no pipeline de compilação nativa.

2. **VM Stack Bytecode Soberana em Kaz Puro (`compiler/vm.kaz`):**
   - Interpretador de bytecode de pilha escrito 100% em código Kaz, implementando os 88 opcodes oficiais da especificação `.kzc`.
   - Deserialização binária de cabeçalho `KZBC`, tabela de strings e pools de constantes.

3. **Arquitetura JIT Moderna com Cranelift (`tools/cranelift-jit/`):**
   - Estrutura para substituir o JIT monolítico legado em Rust.
   - Ponte C ABI enxuta com gerenciamento de memória executável (`mprotect`/`RX`) combinada a um frontend em Kaz puro.

4. **Motor de IA & Quantização AVX2:**
   - Suporte ao formato binário `.kzm` com aceleração vetorial SIMD AVX2 em registradores para dequantização de pesos e multiplicação de tensores.
   - Avaliação de acurácia bit-idêntica validada pelo script soberano `score.kaz`.

---

## 3. Verificação & Smoke Test

O teste de fumaça inicial foi executado e aprovado com sucesso:
- **Código:** `function Main(): int { return 42; }`
- **Binário Gerado:** `minimal_42.elf` (ELF 64-bit LSB executable, x86-64, statically linked, no section header).
- **Execução:**
  ```bash
  $ ./minimal_42.elf
  $ echo "EXIT CODE: $?"
  EXIT CODE: 42
  ```
