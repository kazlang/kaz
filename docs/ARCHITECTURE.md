# Internal Architecture & Compilation Engineering 🏛️

The **Kaz** programming language combines Rust-inspired type safety with a modern compilation pipeline targeting an optimized **Stack-Based Bytecode Virtual Machine (Stack VM)** and direct **Native AOT x86-64 Machine Code Generation**.

This document details the complete execution pipeline, from `.kaz` source code to native bare-metal execution and VM instruction dispatch.

---

## 📑 Table of Contents

1. [Pipeline Overview](#1-pipeline-overview)
2. [Lexical & Syntactic Analysis (Pratt Parser)](#2-lexical--syntactic-analysis)
3. [Abstract Syntax Tree (AST)](#3-abstract-syntax-tree-ast)
4. [Module Resolution & Multi-File Dependencies](#4-module-resolution--multi-file-dependencies)
5. [The Bytecode Compiler](#5-the-bytecode-compiler)
6. [Instruction Set Architecture (`OpCode`)](#6-instruction-set-architecture-opcode)
7. [The Stack Virtual Machine & Stack Unwinding](#7-the-stack-virtual-machine--stack-unwinding)
8. [Embedded Native Standard Library (Batteries Included)](#8-embedded-native-standard-library)
9. [Diagnostic and Debugging Subsystems](#9-diagnostic-and-debugging-subsystems)
10. [Performance Profile: AST vs Stack VM](#10-performance-profile-ast-vs-stack-vm)
11. [Native AOT x86-64 Architecture (`src/aot/`)](#11-native-aot-x86-64-architecture)
12. [Self-Hosted Compiler & AOT Fixed Point (Milestone 5)](#12-self-hosted-compiler--aot-fixed-point)

---

## 1. Pipeline Overview

```text
┌─────────────────┐     ┌────────────────┐     ┌────────────────┐
│   Source Code   │ ──> │  Pratt Parser  │ ──> │      AST       │
│    (*.kaz)      │     │  & Lexer       │     │   Structures   │
└─────────────────┘     └────────────────┘     └────────┬───────┘
                                                        │
                         ┌──────────────────────────────┴──────────────────────────────┐
                         ▼                                                             ▼
              ┌─────────────────────┐                                       ┌─────────────────────┐
              │  Bytecode Compiler  │                                       │   AOT x86-64 Emitter│
              └──────────┬──────────┘                                       └──────────┬──────────┘
                         ▼                                                             ▼
              ┌─────────────────────┐                                       ┌─────────────────────┐
              │ Stack VM Dispatch   │                                       │ NASM + GNU LD Linker│
              │ (Zero Runtime Deps) │                                       │ (Standalone ELF64)  │
              └─────────────────────┘                                       └─────────────────────┘
```

---

## 2. Lexical & Syntactic Analysis

The parser employs a top-down operator precedence mechanism (**Pratt Parser**), guaranteeing:
- Deterministic handling of arithmetic, logical, and bitwise precedence.
- Clear, descriptive syntax error diagnostics with line, column, and token highlights.
- First-class support for ternary expressions, typed arrays, and struct instantiation.

---

## 3. Abstract Syntax Tree (AST)

The AST acts as the intermediate semantic foundation. Expressions and statements are structured into clean, strongly typed variants representing:
- Variable declarations (`let`, `mut`, `const`).
- Control flow (`if`/`else`, `for..in`, `while`, `match`).
- Structs and field mutations.
- Function definitions, closures, and test blocks (`test "..." { ... }`).

---

## 4. Module Resolution & Multi-File Dependencies

Kaz natively resolves imports with circular-dependency protection:
- `import "math_utils.kaz"`
- Folder-based packages with `mod.kaz` or `main.kaz` entrypoints.
- Automatic deduplication ensuring each compilation unit is parsed and emitted once.

---

## 5. The Bytecode Compiler

The compiler lowers the AST into a linear stream of compact 8-bit opcodes:
- Local variable resolution maps identifiers to zero-cost stack frame offsets.
- Loop jumps and conditional branches use backpatching for relative offset computation.
- Constant pool deduplication minimizes memory footprint.

---

## 6. Instruction Set Architecture (`OpCode`)

The VM operates on a lean instruction set:
- Stack operations: `PushConst`, `Pop`, `Dup`.
- Arithmetic & Bitwise: `Add`, `Sub`, `Mul`, `Div`, `Mod`, `BitAnd`, `BitOr`, `BitXor`, `Shl`, `Shr`.
- Variable Management: `LoadLocal`, `StoreLocal`, `LoadGlobal`, `StoreGlobal`.
- Control Flow: `Jump`, `JumpIfFalse`, `Call`, `Return`.
- Structs & Arrays: `NewStruct`, `GetField`, `SetField`, `NewArray`, `GetIndex`, `SetIndex`.

---

## 7. The Stack Virtual Machine & Stack Unwinding

The Kaz Stack VM executes instructions inside a high-speed dispatch loop:
- Call frames manage instruction pointers (`ip`), local base pointers, and return values.
- Uncaught runtime exceptions trigger deterministic **stack unwinding** displaying file, line, and function backtraces.

---

## 8. Embedded Native Standard Library

All standard library modules (`io`, `math`, `str`, `arr`, `fs`, `crypto`, `regex`, `net`, `db`, `json`) are compiled statically into the host binary without external runtime library links.

---

## 9. Diagnostic and Debugging Subsystems

The toolchain provides native flags for developer observability:
- `kaz --disasm <file.kaz>`: Human-readable bytecode disassembly with operand decoding.
- `kaz --dump-ast <file.kaz>`: Structural syntax tree inspection.

---

## 10. Performance Profile: AST vs Stack VM

Execution through the Stack VM achieves up to **30x-40x** performance gains over naive tree-walking AST interpretation, delivering predictable execution latency suitable for real-time systems.

---

## 11. Native AOT x86-64 Architecture (`src/aot/`) ⚙️

The AOT subsystem translates Kaz code directly into **pure standalone x86-64 machine code**, producing static ELF64 executables with **zero dependencies** on libc or virtual machines:

```text
  ┌───────────────────────────────────────────────────────────┐
  │         Native AOT Backend (`src/aot/mod.rs`)             │
  │   - Static type inference over abstract stack             │
  │   - Direct hardware register and RBP slot mapping         │
  │   - Clean Intel-syntax NASM assembly generation           │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │                 NASM Assembler (elf64)                    │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │               GNU LD (Static ELF64 Linker)                │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │        Standalone Native Executable (~10-12 KB)           │
  │   - Direct Linux syscalls (sys_write, sys_exit)           │
  │   - On-demand dynamic heap allocator via sys_brk(12)      │
  │   - Zero runtime dependencies                             │
  └───────────────────────────────────────────────────────────┘
```

### Memory Layout and Heap Primitives:
1. **Dynamic Heap Arena (`kaz_alloc`)**:
   - High-performance bump allocator expanding dynamically via `sys_brk(12)` in 64 MB blocks.
2. **Structs**:
   - `Offset 0`: Field count (`field_count`).
   - `Offset 8`: Pointer to struct name string.
   - `Offset 16 + i*16`: Field key pointer (`key_ptr`).
   - `Offset 24 + i*16`: Field value quadword (`val_qword`).
3. **Arrays**:
   - `Offset 0`: Length (`len`).
   - `Offset 8`: Capacity (`cap`).
   - `Offset 16 + i*8`: Contiguous 64-bit elements.
4. **Strings**:
   - Static string literals are emitted into `.rodata` as null-terminated UTF-8 byte streams.
   - Dynamic concatenation (`kaz_str_concat`) allocates memory on the heap and executes linear buffer copies preserving null terminators.

---

## 12. Self-Hosted Compiler & AOT Fixed Point (Milestone 5) 🦅

In version 1.5.0, the Kaz programming language achieved complete sovereignty (*self-hosting*) with formal verification of **Deterministic Fixed Point (Ponto Fixo)**.

### Multi-Stage Bootstrap Pipeline:
1. **Stage 1 (Host Rust Compiler)**: Compiles the compiler source code written in pure Kaz (`compiler/*.kaz`) into x86-64 assembly.
2. **Stage 2 (Native Assembly & Linking)**: Assembles the generated assembly via NASM and links with GNU LD, producing the standalone executable `kazc_stage2` (269 KB).
3. **Stage 3 (Native Sovereign Self-Compilation)**: The native executable `kazc_stage2` compiles `compiler/*.kaz` without any dependency on Rust or VM runtimes, producing `kazc_stage3.asm` (2.3 MB) in under 40 seconds.
4. **Stage 4 & Fixed Point Proof**: The resulting Stage 3 binary compiles the compiler again, producing `kazc_stage4.asm`.
   - **Bit-for-Bit Determinism**: The diff between `kazc_stage3.asm` and `kazc_stage4.asm` is completely empty, with mathematically identical SHA-256 cryptographic hashes:
     `95398a3ce2056ca043767774130fa07593da2f7b3b7ad5e0ad265679a29d7ae8`.

### Dynamic Heap via Linux Syscalls (`sys_brk`):
To eradicate buffer overflow vulnerabilities associated with giant static `.bss` allocations without introducing libc dependencies:
- Static `.bss` memory is reduced to just 24 bytes for pointer tracking (`kaz_heap_start`, `kaz_heap_current`, `kaz_heap_limit`).
- The AOT runtime invokes the direct Linux kernel syscall `sys_brk(12)` (`kaz_expand_heap`).
- Memory grows dynamically in 64 MB chunks on demand, enabling native kernel paging management and preventing unintended physical memory exhaustion.
