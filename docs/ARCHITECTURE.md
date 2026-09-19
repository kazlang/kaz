# Arquitetura Interna & Engenharia de Compilação 🏛️

A linguagem **Kaz** combina a segurança de tipos inspirada em Rust com uma arquitetura moderna de compilação para **Máquina Virtual de Bytecode baseada em Pilha (Stack VM)**.

Este documento detalha o pipeline completo de execução, desde o código-fonte `.kaz` até o ciclo de instruções na VM.

---

## 📑 Sumário

1. [Visão Geral do Pipeline](#1-visão-geral-do-pipeline)
2. [Análise Léxica & Sintática (Parser PEG + Pratt)](#2-análise-léxica--sintática)
3. [Árvore Sintática Abstrata (AST)](#3-árvore-sintática-abstrata-ast)
4. [Resolução de Módulos & Dependências](#4-resolução-de-módulos--dependências)
5. [O Compilador de Bytecode](#5-o-compilador-de-bytecode)
6. [Conjunto de Instruções (`OpCode`)](#6-conjunto-de-instruções-opcode)
7. [A Máquina Virtual de Pilha (Kaz Stack VM)](#7-a-máquina-virtual-de-pilha-kaz-stack-vm)
8. [Módulos Nativos Embutidos (SQLite, JSON, Rede)](#8-módulos-nativos-embutidos)
9. [Comparativo de Desempenho: AST vs Stack VM](#9-comparativo-de-desempenho-ast-vs-stack-vm)

---

## 1. Visão Geral do Pipeline

```
  ┌───────────────────────────────────────────────────────────┐
  │                    Código-Fonte (.kaz)                    │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │  1. Frontend: Lexer PEG (Pest) + Pratt Parser             │
  │     - Tokenização e validação de regras gramaticais       │
  │     - Resolução estrita de precedência de operadores      │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │  2. Árvore Sintática Abstrata (AST com Spans de Depuração)│
  │     - Stmt (Declarações, Funções, Structs, Loops)         │
  │     - Expr (Literais, Chamadas, Ternário, Binários)       │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │  3. Compilador de Bytecode & Resolvedor de Módulos        │
  │     - Resolução recursiva de imports com proteção anti-loop│
  │     - Mapeamento estático de variáveis em slots de pilha   │
  │     - Patching de saltos (Jumps) para loops e condicionais │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │  4. Chunks de Bytecode (Instruções Lineares Contíguas)    │
  │     - Pool de Constantes, Tabela de Funções Compiladas    │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │  5. Kaz Stack VM (Runtime em Rust de Alta Performance)    │
  │     - Despacho ultra-rápido de OpCodes em memória linear  │
  │     - Integração direta com SQLite, Serde JSON e Rede TCP │
  └───────────────────────────────────────────────────────────┘
```

---

## 2. Análise Léxica & Sintática

- **Gramática PEG (`src/grammar.pest`)**: Utiliza Parsing Expression Grammar formal, garantindo que não haja ambiguidades sintáticas.
- **Pratt Parser (`src/parser.rs`)**: Para operadores binários, lógicos, unários e ternários, utiliza o algoritmo de Pratt, assegurando que expressões complexas como `(a + b * c > d) ? e : f` sejam agrupadas rigorosamente segundo a tabela padrão de precedência.

---

## 3. Árvore Sintática Abstrata (AST)

Definida em `src/ast.rs`, a AST representa as intenções do desenvolvedor em estruturas fortemente tipadas em Rust:
- `Stmt`: Declarações de variáveis, funções (`Stmt::FunctionDecl`), estruturas (`Stmt::StructDef`), condicionais (`Stmt::If`), loops (`Stmt::For`, `Stmt::ForIn`, `Stmt::While`) e comandos de importação (`Stmt::Import`).
- `Expr`: Operações aritméticas, chamadas de método, instanciação de structs e operadores ternários (`Expr::Ternary`).
- `Span`: Cada nó preserva linha e coluna exatas no arquivo de origem para relatórios precisos de erros.

---

## 4. Resolução de Módulos & Dependências

O resolvedor de módulos em `src/vm/compiler.rs`:
1. **Resolução Relativa**: Quando `src/main.kaz` executa `import "models/user.kaz"`, o caminho é resolvido em relação à pasta de `main.kaz`, e não ao diretório de trabalho do terminal.
2. **Cache Canônico Anti-Ciclo**: Um `HashSet<String>` com os caminhos canônicos normalizados impede que o mesmo módulo seja compilado mais de uma vez, evitando loops infinitos (ex: Módulo A importa Módulo B e Módulo B importa Módulo A).
3. **Fusão de Símbolos**: Structs e funções compiladas em módulos secundários são integradas ao mapa global de execução, mantendo a função `Main()` raiz protegida contra sobreposição.

---

## 5. O Compilador de Bytecode

Localizado em `src/vm/compiler.rs`, o compilador transforma a AST em chunks de bytecode contíguos:
- **Resolução Estática de Variáveis Locais**: Durante a compilação, cada variável local recebe um slot fixo de pilha (`u16`). Em tempo de execução, a leitura dessa variável não faz nenhuma busca em strings ou hash maps: acessa diretamente o array de memória por offset (`OpCode::GetLocal(slot)`).
- **Backpatching de Saltos (Jumps)**: Para condicionais e loops, o compilador emite instruções com saltos provisórios (`OpCode::Jump(0)`) e atualiza o endereço de salto assim que o bloco termina (`patch_jump`).

---

## 6. Conjunto de Instruções (`OpCode`)

O conjunto de instruções de Kaz (`src/vm/opcode.rs`) é compacto e focado em operações eficientes de pilha:

| OpCode | Descrição |
|---|---|
| `Constant(u16)` | Empilha uma constante do pool da VM. |
| `DefGlobal(u16, bool, DataType)` | Registra uma variável global com metadados de tipo e constância. |
| `GetGlobal(u16)` / `SetGlobal(u16)` | Lê ou atualiza variável global pelo índice do nome. |
| `GetLocal(u16)` / `SetLocal(u16)` | Lê ou atualiza variável local por offset de pilha (**tempo O(1)**). |
| `Add`, `Subtract`, `Multiply`, `Divide`, `Modulo` | Operações aritméticas de topo de pilha. |
| `Equal`, `NotEqual`, `Greater`, `Less`, etc. | Comparações relacionais. |
| `Jump(u16)`, `JumpIfFalse(u16)`, `Loop(u16)` | Desvios incondicionais e condicionais de fluxo. |
| `Call(u8)` / `CallNative(u16, u8)` | Chamada de funções de usuário ou da biblioteca padrão. |
| `Return` | Retorno da chamada desempilhando o frame de execução. |
| `Halt` | Encerramento do programa. |

---

## 7. A Máquina Virtual de Pilha (Kaz Stack VM)

A Stack VM (`src/vm/vm.rs`) implementa o loop de despacho das instruções:
- **CallFrames**: Cada chamada de função aloca um frame contendo ponteiro de instrução (`ip`), chunk local e ponteiro de base da pilha (`stack_ptr`).
- **Valores Primitivos Eficientes**: O enum `Value` armazena inteiros de 64 bits, floats, booleanos e strings com alocação mínima.
- **Isolamento de Escopo em Loops**: Ao término de cada iteração de repetição, a VM descarta as variáveis temporárias emitindo instruções `Pop`, mantendo o tamanho da pilha estável independentemente do número de voltas.

---

## 8. Módulos Nativos Embutidos

Diferente de interpretadores que exigem instalação de pacotes C externos, Kaz incorpora em Rust:
1. **SQLite Bundled (`src/stdlib/db.rs`)**: O código C do SQLite 3 é compilado estaticamente para dentro do binário `kaz.exe`. Suporta bancos em memória (`:memory:`) e arquivos persistentes.
2. **Serde JSON (`src/stdlib/json.rs`)**: Parser e gerador JSON ultra-otimizados que mapeiam diretamente entre árvores JSON e structs/arrays Kaz.
3. **Rede TCP / HTTP (`src/stdlib/net.rs`)**: Medição de ping via handshake TCP nativo e requisições HTTP RESTful com sockets padrão do sistema.

---

## 9. Comparativo de Desempenho: AST vs Stack VM

Em testes de estresse computacional (`examples/benchmark.kaz`):

| Teste de Benchmark | Interpretador AST Clássico | Kaz Stack Bytecode VM | Ganho de Desempenho |
|---|---|---|---|
| **Loop Aritmético (50.000 iterações)** | 420 ms | **21 ms** | **20x mais rápido** |
| **Alocação de 10.000 Structs** | 890 ms | **70 ms** | **12.7x mais rápido** |
| **Fibonacci 26 (242.785 chamadas)** | ~18.500 ms | **638 ms** | **28.9x mais rápido** |
| **Tempo Total da Suíte** | ~19.810 ms | **729 ms** | **27x mais rápido** |
