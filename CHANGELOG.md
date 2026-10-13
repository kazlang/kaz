# Changelog 🦅

Todas as mudanças notáveis no projeto **Kaz** serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

---

## [1.4.0] - 2026-10-12

### 🚀 Adicionado & Concluído (Milestone 4 - Compilador Nativo AOT x86-64 Completo)
- **Compilador Nativo AOT Direto (`kaz build`)**:
  - O comando `kaz build <arquivo.kaz> [-o saida]` agora compila diretamente programas Kaz para binários executáveis **ELF64 x86-64 estáticos, puros e autônomos (~10 KB)** com montagem via NASM e linkagem via GNU LD.
  - Binários gerados rodam diretamente em bare-metal com **zero dependências** de runtime, libc ou máquinas virtuais intermediárias.
  - Módulo nativo implementado em Rust puro em [`src/aot/mod.rs`](file:///home/armando/Projetos/kaz/src/aot/mod.rs) e utilitário autônomo em [`tools/kazaot.py`](file:///home/armando/Projetos/kaz/tools/kazaot.py).
- **Suporte Abrangente a Toda a Linguagem Kaz no Backend Nativo**:
  - **Aritmética, Variáveis & Controle**: Operações de 64 bits (`Add`, `Sub`, `Mul`, `Div`, `Mod`), comparações relacionais e condicionais, laços `while` e variáveis locais indexadas em pilha de hardware `[rbp - 8*(slot+1)]`.
  - **Funções de Usuário & Recursão Profunda**: Convenção de chamada nativa com prólogo/epílogo `rbp/rsp` e passagem de parâmetros em pilha. Fibonacci recursivo (`fib(25) = 75025`) executa em apenas **4ms** (55x mais rápido que na Stack VM).
  - **Structs no Heap**: Alocação via Bump Allocator (`kaz_alloc`), inicialização de campos com `BuildStruct`, leitura com `GetField` via `kaz_strcmp` e mutação de campos aninhados com `SetNested`.
  - **Arrays Nativos**: Alocação de arrays dinâmicos no heap com cabeçalhos de tamanho e capacidade (`BuildArray`), indexação direta SIB scale `*8` (`GetIndexLocal`, `GetIndexGlobal`, `GetIndex`) e mutação (`SetIndex`).
  - **Strings & Concatenação Nativas**: Mapeamento de literais terminados em nulo na seção `.rodata`, rotina de concatenação em hardware (`kaz_str_concat`) com inferência estática de tipos de operandos e impressão formatada via chamadas diretas de sistema `sys_write` (`kaz_builtin_print_str`, `kaz_builtin_print_cstr`).
  - **Enums com Dados & Pattern Matching**: Alocação contígua de variantes com múltiplos payloads (`BuildEnum`), checagem condicional com `CheckEnum` e desestruturação tipada com `GetEnumField`.
- **Suíte de Testes Nativos AOT**:
  - Testes unitários cobrindo todo o pipeline em `tests/test_aot_*.kaz` (simples, loops, fibonacci recursivo, structs, arrays, strings e enums com pattern matching) validados com 100% de sucesso.

---

## [1.3.0] - 2026-10-06

### 🚀 Adicionado & Concluído (Milestone 3 - Self-Hosting Completo)
- **Compilador Self-Hosted Totalmente Operacional (`kazc.kzc`)**:
  - Compilação do compilador Kaz escrito puramente em Kaz (`compiler/*.kaz`), gerando o binário `kazc.kzc` (103.277 bytes, 84 funções de usuário).
  - Execução bem-sucedida da **Compilação Triangular (Milestone 3.4)**: `kazc.kzc compiler/main.kaz kazc_v2.kzc`.
  - Validação bit a bit: `sha256sum kazc.kzc kazc_v2.kzc` idêntico (`06cd8e2ce981ace55927ed8ad6fcd05528713da5618a708fdbbd5b8a8bb99750`).
- **Serialização Completa de Funções de Usuário em Bytecode `.kzc`**:
  - Extensão do formato binário `.kzc` com `serialize_program_to_bytes` e `deserialize_program_from_bytes` em Rust e em Kaz (`program_serialize_bytes`).
  - Suporte a inspeção e desmontagem direta de arquivos `.kzc` pelo comando `kaz debug arquivo.kzc`.
- **Otimização O(1) de Arenas e OpCodes de Acesso Rápido**:
  - Novos opcodes de alto desempenho: `PushLocal`, `PushGlobal`, `GetIndexLocal`, `GetIndexGlobal`, `GetFieldLocal`, `GetFieldGlobal`, `SetNested` e `DupNested`.

### 🐛 Corrigido
- **Dessincronização de Pilha por Literais Booleanos no Codegen**:
  - Implementação de `chunk_add_bool`, `chunk_find_bool` e suporte nativo a `LiteralBool`, `LiteralNull` e `LiteralChar` no `codegen.kaz` e `bytecode.kaz`, corrigindo desempilhamento indevido no `continue`.
- **Passagem de Array por Valor em Atribuições Aninhadas**:
  - Desacoplamento do acumulador de caminho em `parser_extract_assign_path` para o vetor global `g_assign_path`, corrigindo corrupção de variáveis de estado no `parser.kaz`.
- **Desacoplamento de Estado do Pratt Parser**:
  - Eliminação de cópias de structs pesadas por valor na recursão do parser, reduzindo tempo de compilação em 99%.

---

## [1.2.0] - 2026-10-02

### 🚀 Adicionado
- **Compilação e Execução de Bytecode Serializado (`.kzc`)**:
  - Novo comando `kaz compile arquivo.kaz -o saida.kzc` para gerar binários portáteis de bytecode compactos e autocontidos.
  - O comando `kaz run arquivo.kzc` detecta o cabeçalho mágico `KAZC` e despacha para a VM com inicialização instantânea sub-milissegundo.
  - Implementação de serialização e deserialização contígua de OpCodes e tabela de constantes em `src/vm/chunk.rs`.
- **Compilador Self-Hosted (Etapa 2 do Bootstrap)**:
  - Implementação do compilador auto-hospedado em `compiler/` puramente em Kaz (Lexer, Pratt Parser, Codegen e Bytecode Serializer).
  - Capacidade da linguagem Kaz de compilar programas e emitir arquivos binários `.kzc` diretamente.
- **Novas Funções Nativas de Conversão**:
  - `to_char_code(ch)` e `ord(ch)` registradas no runtime e compilador da VM.

### 🐛 Corrigido
- **Ambiguidade de Tipos na Gramática Pest (`src/grammar.pest`)**:
  - Adicionado delimitador atômico (`!(ASCII_ALPHANUMERIC | "_")`) para tipos primitivos (`int`, `char`, `float`, etc.), arrays e maps, prevenindo que atribuições iniciadas por prefixos de tipos (como `char_idx = ...`) fossem desambiguadas como declarações inválidas.

---

## [1.1.0] - 2026-09-25

### 🚀 Adicionado
- **Scaffolding de Projetos (`kaz new` / `kaz create`)**:
  - Novo comando para criação instantânea de projetos estruturados em pastas.
  - Gera manifesto `kaz.json` com metadados do projeto, autor e ponto de entrada (`entrypoint`).
  - Estrutura inicial completa com pasta `src/`, `data/`, `tests/`, `.gitignore` e `README.md`.
  - Módulo nativo `src/database.kaz` com inicialização e migração automática de banco SQLite (`data/app.db`).
  - Modelos de domínio em `src/models/usuario.kaz` e testes unitários automatizados em `tests/main_test.kaz`.
- **Descoberta Inteligente de Raiz de Projeto (`kaz.json`)**:
  - Compilador (`src/vm/compiler.rs` e `src/evaluator.rs`) agora sobe a árvore de diretórios localizando o manifesto `kaz.json`.
  - Permite importar módulos com caminhos absolutos relativos à raiz (`import "src/models/..."`) a partir de subpastas ou testes sem erros de caminho relativo.
- **Nova Identidade Visual Oficial**:
  - Logotipo oficial do Kaz reformulado com visual estilizado em alta definição e tipografia 3D galáctica em degradê.
- **Suíte de Testes Automatizados para Projetos**:
  - Novo arquivo de testes de integração [`tests/project_tests.rs`](file:///C:/ProjetosAM/kaz/tests/project_tests.rs), validando criação, proteção contra sobreposição em pastas ocupadas, execução na Stack VM e runner de testes unitários.

### 🛡️ Segurança (Auditoria de Código SAST)
- **Eliminação de Command Injection (`src/shell.rs`)**:
  - Substituição da invocação intermediária via shell (`cmd /C` e `sh -c`) por execução nativa de processos pelo sistema operacional via `Command::new(program).args(args)`.
- **Sanitização de Caminhos de Executável (`src/builder.rs`)**:
  - Proteção contra *Symlink Spoofing* e adulteração de caminhos relativos ao envolver `env::current_exe()` com `fs::canonicalize()` e checagem `is_file()`.
- **Concorrência Segura no Runtime ARC (`src/jit/runtime.rs`)**:
  - Substituição dos arrays estáticos mutáveis globais `static mut DROP_TABLE` e `static mut MANAGED_OFFSETS` por containers thread-safe com travas de leitura/escrita concorrente (`std::sync::RwLock`).
- **Eliminação de Safety Bypass (`src/jit/runtime.rs`)**:
  - Remoção de `#![allow(clippy::not_unsafe_ptr_arg_deref)]`.
  - Funções de baixo nível que manipulam ponteiros brutos explicitadas formalmente como `pub unsafe extern "C" fn`, aderindo estritamente aos padrões do Rust 2024.

### 🔄 Refatoração & Padronização
- **Padronização de Saída para `runoff()`**:
  - Substituição de chamadas legadas de `print` e `println` pela função canônica `runoff()` em toda a documentação, exemplos e templates gerados.
- **Adoção Canônica da Convenção `camelCase`**:
  - Todas as funções utilitárias e variáveis foram refatoradas para `camelCase` (ex: `inicializarBanco`, `inserirUsuario`, `listarUsuarios`, `criarUsuario`, `formatarUsuario`).
- **Suporte Avançado a Laços e Atribuições**:
  - Suporte a operadores de atribuição compostos (`+=`, `-=`, `*=`, `/=`, `%=`).
  - Laço `for (item in colecao)` com suporte pleno a aninhamento e controle de fluxo (`break`/`continue`).

---

## [1.0.0] - 2026-09-20

### 🚀 Lançamento Inicial
- **Stack Bytecode Virtual Machine**: Motor de execução em bytecode compilado com tabela de símbolos, constantes e instruções lineares de alto desempenho.
- **Interpretador de AST Clássico**: Motor de referência para validação semântica e depuração visual.
- **Compilador JIT Cranelift**: Geração de código de máquina nativo x86_64 em tempo de execução.
- **Biblioteca Padrão Embutida (Stdlib)**:
  - SQLite embutido no executável (`db_open`, `db_execute`, `db_query`, `db_close`).
  - Serialização e parsing de JSON (`json_parse`, `json_stringify`).
  - Manipulação de arquivos (`fs_read`, `fs_write`, `fs_mkdir`, `fs_remove`, `fs_exists`).
  - Funções matemáticas e de rede (`net_ping`, `net_http_get`).
- **Ferramental de Linha de Comando (CLI)**:
  - Execução de arquivos individuais (`kaz run arquivo.kaz`) e diretórios inteiros (`kaz meu_projeto/`).
  - Executor nativo de testes unitários (`kaz test`).
  - Formatador canônico de código (`kaz fmt`).
  - Terminal interativo integrado (`kaz shell`) e REPL (`kaz repl`).
  - Gerador de executáveis autônomos (`kaz build`).
- **Extensão para IDEs**:
  - Pacote de suporte sintático para Visual Studio Code e Lumina IDE.
