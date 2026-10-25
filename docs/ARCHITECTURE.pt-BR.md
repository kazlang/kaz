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
7. [A Máquina Virtual de Pilha & Stack Unwinding (Kaz Stack VM)](#7-a-máquina-virtual-de-pilha--stack-unwinding-kaz-stack-vm)
8. [Módulos Nativos Embutidos (Bateria Inclusa)](#8-módulos-nativos-embutidos-bateria-inclusa)
9. [Ferramentas Nativas de Diagnóstico e Depuração](#9-ferramentas-nativas-de-diagnóstico-e-depuração)
10. [Comparativo de Desempenho: AST vs Stack VM](#10-comparativo-de-desempenho-ast-vs-stack-vm)

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
| `PushTry(u16)` | Registra manipulador de exceção na VM com ponteiro de salto para o catch. |
| `PopTry` | Remove o manipulador de exceção ativo ao finalizar o bloco `try` com sucesso. |
| `Call(u8)` / `CallMethod(u16, u8)` | Chamada de funções de usuário ou métodos de tipos complexos. |
| `CallNative(u16, u8)` | Chamada direta de funções da biblioteca padrão implementadas em Rust. |
| `Return` | Retorno da chamada desempilhando o frame de execução e limpando handlers expirados. |
| `Halt` | Encerramento do programa. |

---

## 7. A Máquina Virtual de Pilha & Stack Unwinding (Kaz Stack VM)

A Stack VM (`src/vm/vm.rs`) implementa o loop de despacho das instruções em memória contígua:
- **CallFrames**: Cada chamada de função aloca um frame contendo ponteiro de instrução (`ip`), chunk local e ponteiro de base da pilha (`stack_start`).
- **Valores Primitivos Eficientes**: O enum `Value` armazena inteiros de 64 bits, floats, booleanos, structs e strings com alocação mínima.
- **Tratamento de Exceções & Desenrolamento (*Stack Unwinding*)**:
  - Quando um erro ocorre durante a execução (aritmético, I/O, SQL, asserção, limites), o método `handle_error` consulta o vetor `exception_handlers`.
  - Os call frames são desenrolados até o frame onde o `PushTry` foi registrado.
  - A pilha de operandos é truncada diretamente para `handler.stack_depth`, eliminando todos os valores intermediários acumulados.
  - A mensagem de erro em `Value::String` é empilhada para ser vinculada à variável do `catch` (ou descartada via `Pop`).
  - O ponteiro `frame.ip` é redirecionado instantaneamente para `handler.catch_ip`.
  - **Custo Zero (*Zero-Overhead*)**: Na ausência de exceções, `PushTry` e `PopTry` são operações de custo irrisório sem nenhuma sobrecarga de captura ou checagem em cada instrução.

---

## 8. Módulos Nativos Embutidos (Bateria Inclusa)

Diferente de interpretadores que exigem instalação de pacotes C externos ou gerenciadores de pacotes pesados, Kaz incorpora tudo em Rust:
1. **SQLite 3 Bundled (`src/stdlib/db.rs`)**: Compilado estaticamente para dentro do binário `kaz.exe`. Suporta bancos em memória (`:memory:`) e arquivos persistentes em disco.
2. **Criptografia & Hashes (`src/stdlib/crypto.rs`)**: Implementações nativas de SHA-256 (`sha2`), MD5 (`md-5`) e codificação/decodificação Base64 (`base64`).
3. **Expressões Regulares (`src/stdlib/regex.rs`)**: Motor de regex de alta performance baseado na crate Rust `regex`.
4. **Sistema de Arquivos Moderno (`src/stdlib/fs.rs`)**: Operações completas de `mkdir -p`, leitura recursiva de diretórios, cópia, verificação de tamanho e remoção segura.
5. **Serde JSON (`src/stdlib/json.rs`)**: Parser e gerador JSON ultra-otimizados que mapeiam diretamente entre árvores JSON e structs/arrays Kaz.
6. **Rede TCP / HTTP (`src/stdlib/net.rs`)**: Medição de ping via handshake TCP nativo e requisições HTTP RESTful com sockets padrão do sistema.

---

## 9. Ferramentas Nativas de Diagnóstico e Depuração

Kaz não requer a instalação de ferramentas externas para inspeção ou testes:
- **`kaz trace <arquivo.kaz>`**: Executa o programa exibindo o ciclo de despacho de cada OpCode, número de linha, Instruction Pointer (IP) e todo o conteúdo da pilha em tempo real.
- **`kaz debug <arquivo.kaz>`**: Desmonta os chunks de bytecode, exibindo as tabelas de literais e instruções sem executar o programa.
- **`kaz db-cli <banco.db>`**: Console interativo SQLite integrado para consultas, inspeção de esquemas e comandos DDL/DML diretamente pelo terminal.
- **`kaz test [caminho]`**: Executor de testes unitários nativo integrado ao compilador, que ignora os blocos de teste durante `kaz run`, mas os executa com relatório de milissegundos durante `kaz test`.

---

## 10. Comparativo de Desempenho: AST vs Stack VM

Em testes de estresse computacional (`examples/benchmark.kaz`):

| Teste de Benchmark | Interpretador AST Clássico | Kaz Stack Bytecode VM | Ganho de Desempenho |
|---|---|---|---|
| **Loop Aritmético (50.000 iterações)** | 420 ms | **21 ms** | **20x mais rápido** |
| **Alocação de 10.000 Structs** | 890 ms | **70 ms** | **12.7x mais rápido** |
| **Fibonacci 26 (242.785 chamadas)** | ~18.500 ms | **638 ms** | **28.9x mais rápido** |
| **Tempo Total da Suíte** | ~19.810 ms | **729 ms** | **27x mais rápido** |

---

## 11. Backend Nativo Cranelift JIT & Compilador AOT (`kaz jit` e `kaz build`)

Além da Bytecode VM, Kaz incorpora um gerador de código de máquina nativo baseado em **Cranelift** (`src/jit/`):
- **Cranelift JIT (`kaz jit`)**: Compila funções diretamente em tempo de execução para assembly x86_64, alcançando paridade de ~1,8x a 2,1x com binários compilados por Rust (`rustc -O3`) e superando interpretadores tradicionais em mais de 25x.
- **AOT ELF Generator (`kaz build`)**: Empacota o pipeline em executáveis autônomos sem dependências externas.
- **Instruções Intrínsecas de CPU**: Operações matemáticas como `math.sqrt` emitem opcodes de máquina diretos (`sqrtsd %xmm0, %xmm0`) sem overhead de FFI.

---

## 12. Modelo de Segurança de Extensões & Mods: Sandbox VM vs Acelerador JIT

> [!CAUTION]
> **REGRA DE ISOLAMENTO DE EXTENSÕES & SCRIPTS DE TERCEIROS:**
> Por diretriz arquitetural estrita, **todos os scripts de terceiros, plugins e mods devem ser executados exclusivamente na Kaz Bytecode VM (`kaz vm`)**.
> 
> O Cranelift JIT opera como acelerador computacional com ponteiros de máquina diretos (`*mut u8`). Enquanto o modelo de posse e contagem de referências (ARC) estiver em homologação, a garantia de segurança contra Use-After-Free, buffer overflow e corrupção de memória do host é fornecida **exclusivamente pela sandbox da Bytecode VM**, gerenciada pelas garantias de RAII do Rust.

---

## 13. Modelo de Gerenciamento de Memória Nativo: ARC Atômico & Concorrência Thread-Safe

Para o runtime JIT e código compilado, Kaz adota **Contagem Automática de Referências Atômica (ARC - Automatic Reference Counting)** determinística:

1. **Cabeçalho Padronizado de Objeto (16 bytes):**
   - Offset `-16`: `ref_count` gerenciado com `AtomicUsize` (`fetch_add`/`fetch_sub` com ordenação `AcqRel`/`Release`).
   - Offset `-8`: `type_id` (`u64` para despacho de destrutor recursivo).
   - Offset `0`: Início do payload da struct/dados.
2. **Salvaguarda de Threading e Atomicidade Homologada:**
   - O contador de referências foi blindado com `AtomicUsize`, permitindo passagem segura e retenção/liberação concorrente entre múltiplas threads do SO sem corrupção ou corrida de dados.
3. **Regra de Ingestão (Sink Rule) para Coleções:**
   - Funções que retêm ou persistem ponteiros além da chamada (ex: `array.push(item)`, atribuição a campo de struct `p.filho = outro`, registro em tabelas globais) emitem `retain` obrigatório antes de armazenar o endereço.
4. **Tabela Dinâmica de Destrutores Recursivos (Dynamic Drop Registry):**
   - Tabela protegida por `RwLock` com crescimento sob demanda que suporta milhares de structs (`type_id` dinâmico sem limite rígido de 256), com liberação recursiva de campos gerenciados (managed offsets).

---

## 14. Compilador Self-Hosted (`compiler/`)

A linguagem Kaz possui seu próprio compilador escrito integralmente em Kaz puro (`compiler/`):
- **Lexer (`compiler/lexer.kaz`)**: Tokenizador completo sem dependência de geradores externos.
- **Pratt Parser (`compiler/parser.kaz`)**: Analisador de precedência e árvores sintáticas baseadas em arenas contíguas (`compiler/ast.kaz`).
- **Bytecode CodeGen (`compiler/codegen.kaz`)**: Emissor de instruções lineares compatíveis com o formato binário e a Stack VM Kaz (`compiler/bytecode.kaz`).
- **Driver CLI (`compiler/main.kaz`)**: Orquestrador e gerador de disassembly nativo.
---

## 15. Arquitetura do Compilador Nativo AOT x86-64 (`src/aot/`) ⚙️

O subsistema AOT do Kaz traduz código Kaz para **código de máquina nativo x86-64 autônomo**, gerando binários estáticos ELF64 com zero dependências de libc ou VM:

```
  ┌───────────────────────────────────────────────────────────┐
  │                 Código-Fonte Kaz (.kaz)                   │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │       Frontend Kaz (AST & Compilador de Bytecode)         │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │         Backend AOT Nativo (`src/aot/mod.rs`)             │
  │   - Inferência estática de tipos via pilha abstrata       │
  │   - Mapeamento direto de registradores e slots RBP        │
  │   - Emissão de Assembly x86-64 limpo (sintaxe Intel)      │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │                 NASM Assembler (elf64)                    │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │               GNU LD (Linker Estático ELF64)              │
  └─────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
  ┌───────────────────────────────────────────────────────────┐
  │        Executável Nativo Autônomo (~10-12 KB)             │
  │   - Syscalls Linux diretas (sys_write, sys_exit)          │
  │   - Bump Allocator de Heap integrado (kaz_alloc)          │
  │   - Zero dependências de runtime ou interpretadores       │
  └───────────────────────────────────────────────────────────┘
```

### Layout de Memória e Estruturas no Heap Nativo:
1. **Arena de Heap Dinâmica (`kaz_alloc`)**:
   - Alocador linear (*bump allocator*) de alta performance expandido dinamicamente via `sys_brk(12)` em blocos de 64 MB com alinhamento estrito de 64 bytes para instruções vetoriais SIMD AVX2/AVX-512.
2. **Structs**:
   - `Offset 0`: Quantidade de campos (`field_count`).
   - `Offset 8`: Ponteiro para string com nome da struct.
   - `Offset 16 + i*16`: Chave do campo (`key_ptr`).
   - `Offset 24 + i*16`: Valor do campo (`val_qword`).
3. **Arrays**:
   - `Offset 0`: Comprimento (`len`).
   - `Offset 8`: Capacidade (`cap`).
   - `Offset 16 + i*8`: Elementos contíguos de 64 bits.
4. **Enums (Tagged Unions com Payloads)**:
   - `Offset 0`: Ponteiro para nome do enum (`enum_name`).
   - `Offset 8`: Ponteiro para nome da variante (`variant_name`).
   - `Offset 16`: Quantidade de campos de dados (`payload_count`).
   - `Offset 24 + p*8`: Valores dos payloads ordenados.
5. **Strings & Concatenação**:
   - Literais estáticos são emitidos como bytes UTF-8 terminados em nulo na seção `.rodata`.
   - Concatenação dinâmica (`kaz_str_concat`) aloca o buffer total no heap e realiza cópia sequencial preservando terminação nula.
6. **Buffers Crus com Cabeçalho Tagged (`buf_alloc`)**:
   - `Offset -16`: Capacidade em bytes (`size: qword`).
   - `Offset -8`: Assinatura mágica da tag `0x4B415A42` ('KAZB').
   - `Offset 0 a size-1`: Bytes contíguos de dados úteis.
   - O ponteiro devolvido aos programas Kaz aponta diretamente para o byte 0 (`rax + 16`). As rotinas de acesso (`buf_load_*`, `buf_store_*`) inspecionam `[ptr - 8] == 0x4B415A42`. Caso contenha a tag, os limites são validados (`offset + sizeof(T) <= size`) com checagem de estouro aritmético (`jb kaz_panic_oob`). Se não contiver a tag (ponteiro bruto de `mmap` ou FFI externa), o acesso é direto sem pânico.

### O Tipo Primitivo `decimal` (Ponto Fixo Financeiro & Moeda):
O Kaz incorpora o tipo de ponto fixo exato `decimal`, projetado para cálculos financeiros, contábeis e monetários de alta integridade:
- **Representação**: Inteiro com sinal de 64 bits com escala implícita de $10^4$ (4 casas decimais de precisão exata, ex: `12.3456m`).
- **Eliminação de Erros de Arredondamento Binário**: Elimina as imprecisões de fração binária da norma IEEE-754 ($0.1 + 0.2 \neq 0.3$).
- **Sintaxe Literal**: Sufixo `m` ou `M` (ex: `12.34m`, `0.05m`, `1000m`).
- **Aceleração Nativa em Hardware 128 Bits**: Na compilação AOT x86-64, a aritmética aproveita diretamente o par de registradores de 128 bits `rdx:rax`:
  - Multiplicação calcula $(a \times b) / 10000$ via `imul rbx` seguido de `idiv rcx`.
  - Divisão calcula $(a \times 10000) / b$ via `imul rcx` seguido de `idiv rbx`.
  - Ambas as operações impedem estouro intermediário de 64 bits enquanto executam na velocidade máxima do silício sem alocação em heap.


---

## 16. Compilador Self-Hosted e Ponto Fixo AOT (Milestone 5) 🦅

Na versão 1.5.0, a linguagem Kaz alcançou autonomia completa (*self-hosting*) com verificação formal de **Ponto Fixo Determinístico (Fixed Point)**.

### Pipeline de Bootstrap Multi-Estágio:
1. **Stage 1 (Compilador Host Rust)**: Compila o código-fonte do compilador Kaz (`compiler/*.kaz`) gerando o assembly x86-64 do compilador.
2. **Stage 2 (Montagem & Linkagem Nativa)**: O código assembly gerado é montado via NASM e linkado via LD, produzindo o binário executável autônomo `kazc_stage2` (269 KB).
3. **Stage 3 (Auto-Compilação Nativa Soberana)**: O binário nativo `kazc_stage2` compila o código-fonte do compilador (`compiler/*.kaz`) sem qualquer dependência do executável em Rust, gerando `kazc_stage3.asm` (2.3 MB) em menos de 40 segundos.
4. **Stage 4 & Prova de Ponto Fixo**: O binário gerado do Stage 3 compila novamente o compilador, produzindo `kazc_stage4.asm`.
   - **Garantia Bit-a-Bit**: `diff -u kazc_stage3.asm kazc_stage4.asm` é nulo e os hashes criptográficos SHA-256 são idênticos:
     `95398a3ce2056ca043767774130fa07593da2f7b3b7ad5e0ad265679a29d7ae8`.

### Heap Dinâmico via Syscall Linux (`sys_brk`):
Para eliminar o risco de estouro de buffer associado a reservas estáticas no `.bss` sem sacrificar a independência de libc:
- A seção `.bss` foi reduzida para apenas 24 bytes para ponteiros de controle (`kaz_heap_start`, `kaz_heap_current`, `kaz_heap_limit`).
- O runtime AOT utiliza a syscall direta do kernel Linux `sys_brk(12)` (`kaz_expand_heap`).
- A alocação ocorre dinamicamente em blocos de 64 MB sob demanda, permitindo paginação transparente pelo kernel e prevenindo alocações desnecessárias de memória física.

---

## 17. Arquitetura de Memória: Bump Allocation, Crescimento de Arrays e Prevenção de DoS Remoto 🛡️

### O Modelo Linear Bump Allocator (`kaz_alloc`):
O Kaz AOT utiliza um alocador linear de alto desempenho (*bump allocator*, `kaz_alloc`) projetado para alocação determinística com custo zero de sobrecarga (*zero runtime overhead*) e sem dependência de libc:
- A alocação consiste simplesmente em alinhar o tamanho solicitado para 64 bytes e avançar o ponteiro de heap `kaz_heap_ptr`.
- O alinhamento rigoroso a 64 bytes (`(size + 63) & -64`) garante compatibilidade com instruções vetoriais SIMD AVX2 (32 bytes) e AVX-512 (64 bytes), evitando penalidades de ciclos de CPU ou exceções de desalinhamento de hardware (`#GP`).

### Crescimento Dinâmico de Arrays e Blocos Abandonados:
Quando um array dinâmico cresce via `arr_push`:
1. Se o tamanho atual atingir a capacidade (`len >= cap`), a capacidade é dobrada ($cap_{novo} = cap \times 2$).
2. Um novo bloco contíguo de tamanho $16 + cap_{novo} \times 8$ é alocado em `kaz_heap_ptr`.
3. Os elementos anteriores são copiados para o novo endereço.
4. **O Bloco Anterior Fica Abandonado**: Como um alocador bump não possui free-list individual nem faz desalocações pontuais, o bloco anterior permanece na memória, atrás do ponteiro de heap.
5. **Impacto em Consumo de Memória**: Pela soma geométrica ($\sum_{i=0}^{k-1} 2^i \approx 2^k$), o processo de redimensionamento dinâmico consome no total aproximadamente o dobro ($\approx 2\times$) do tamanho final do array.

### O Risco: Daemons de Longa Execução e DoS Remoto (CWE-400):
Em scripts CLI de curta duração, o alocador bump é ideal: toda a memória é liberada instantaneamente pelo kernel na finalização do processo (`sys_exit`).

No entanto, em **daemons de longa execução** (como servidores TCP com `net_listen` ou multiplexadores interativos como o **TermiKAZ**), alocar arrays dinâmicos repetidamente dentro de laços infinitos causa expansão monotônica contínua do heap:
- **Vulnerabilidade de Negação de Serviço Remota (DoS Remoto)**: Um atacante externo pode disparar requisições em massa propositalmente para forçar o servidor a alocar memória até esgotar o heap (`kaz_panic_oom`) ou provocar encerramento forçado pelo Linux OOM-killer.

```mermaid
flowchart LR
    A["Requisição 1 (Array 16B)"] --> B["Heap Bump (+16B)"]
    B --> C["Redimensionamento (Array 32B)"]
    C --> D["Bloco de 16B Abandonado no Heap"]
    D --> E["Laço Infinito: Crescimento Monotônico"]
    E --> F["Potencial DoS Remoto / Pânico OOM"]
```

### Mecanismos de Mitigação:
O Kaz fornece quatro camadas arquiteturais para garantir segurança e robustez de memória:

1. **Checkpoints e Rewinds de Escopo (`heap_checkpoint` e `heap_rewind`)**:
   Laços de servidores e daemons devem delimitar o escopo transacional de cada requisição:
   ```kaz
   while true {
       let cp = heap_checkpoint();
       let req = net_accept(server);
       handle_request(req);
       heap_rewind(cp); // Reclama instantaneamente toda a memória alocada na requisição!
   }
   ```
   A instrução `heap_rewind(cp)` retrocede `kaz_heap_ptr` para `cp` em tempo $O(1)$, eliminando qualquer vazamento entre requisições sem introduzir pausas de Garbage Collector.

2. **Buffers Contíguos Little-Endian de Tamanho Fixo (`buf_alloc`)**:
   Para operações de I/O de rede, manipuladores de pacotes e tensores de IA, deve-se usar buffers crus de tamanho fixo:
   ```kaz
   let b = buf_alloc(4096); // Alocado uma vez, endereço fixo, sem cópia ou bloco abandonado
   buf_store_u32_le(b, 0, 1337);
   ```
   Buffers possuem ciclo de vida previsível, validação de limites com tags mágicas e imunidade contra abandono de memória em redimensionamento.

3. **Teto Ativo de Heap & Prevenção Anti-OOM (`heap_set_limit`)**:
   Nos sistemas operacionais Linux modernos, a política de *memory overcommit* fica ativa por padrão (`vm.overcommit_memory = 0`). Com isso, invocações de `sys_brk(12)` raramente falham no momento da alocação; em vez disso, o kernel cede endereços virtuais até que a RAM e a partição swap se esgotem completamente, travando a máquina inteira em *thrashing* de I/O antes que o OOM-killer envie um `SIGKILL` arbitrário.
   Para eliminar essa vulnerabilidade:
   - O runtime AOT do Kaz estabelece um teto ativo na seção `.data`: `kaz_heap_max_limit: dq 4294967296` (4 GB por padrão).
   - Em `kaz_alloc`, antes de invocar `sys_brk`, o consumo total acumulado é verificado contra o teto:
     ```nasm
     mov rbx, [kaz_heap_current]
     add rbx, rax ; tamanho alinhado requisitado
     jb kaz_panic_oom ; estouro aritmético de inteiros
     mov r11, [kaz_heap_start]
     add r11, [kaz_heap_max_limit]
     cmp rbx, r11
     ja kaz_panic_oom ; teto ativo excedido!
     ```
   - Aplicações podem configurar um teto dinâmico customizado usando `heap_set_limit(bytes: int)` (ex: `heap_set_limit(512 * 1024 * 1024)` para limitar um sandbox em 512 MB), assegurando que o processo finalize de modo determinístico com saída 1 e diagnóstico claro em `stderr`, sem congelar o sistema operacional hospedeiro.

4. **Plano de Longo Prazo (Milestone 6: Slab/Pool Allocator)**:
   Para suportar dados dinâmicos com ciclo de vida arbitrário fora de checkpoints de escopo, o Kaz introduzirá um alocador pool/slab para arrays com indirection handle (`{ptr, len, cap}`), reciclando blocos descartados.

