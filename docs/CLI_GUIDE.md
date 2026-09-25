# Manual da CLI & Kaz Terminal 🖥️

O utilitário de linha de comando `kaz` é o coração do ecossistema da linguagem, fornecendo ferramentas para executar scripts, gerenciar projetos em pastas, validar código e utilizar o **Kaz Terminal Interativo**.

---

## 📑 Sumário

1. [Instalação & Configuração de PATH](#1-instalação--configuração-de-path)
2. [Execução de Arquivos e Projetos](#2-execução-de-arquivos-e-projetos)
3. [Modos de Execução (VM vs AST)](#3-modos-de-execução-vm-vs-ast)
4. [Validação de Sintaxe (Check)](#4-validação-de-sintaxe-check)
5. [Formatador Canônico de Código (kaz fmt)](#5-formatador-canônico-de-código-kaz-fmt)
6. [Kaz Terminal Interativo (Shell)](#6-kaz-terminal-interativo-shell)
7. [Executor de Testes Nativos (kaz test)](#7-executor-de-testes-nativos-kaz-test)
8. [Ferramentas de Diagnóstico e Debug Nativas](#8-ferramentas-de-diagnóstico-e-debug-nativas)
9. [REPL Simples](#9-repl-simples)
10. [Referência de Opções e Códigos de Saída](#10-referência-de-opções-e-códigos-de-saída)

---

## 1. Instalação & Configuração de PATH

Após executar o instalador (`install.ps1` no Windows ou `install.sh` no Linux/macOS), o binário `kaz` fica disponível em qualquer terminal:

```bash
kaz --version
# Kaz 1.1.0
```

---

## 2. Execução de Arquivos e Projetos

### A. Executar um Arquivo Individual
Basta passar o caminho do arquivo `.kaz`:
```bash
kaz programa.kaz
# ou explicitamente:
kaz run programa.kaz
```

### B. Executar um Projeto Completo em Pasta
Kaz reconhece projetos estruturados. Ao apontar para um diretório, o compilador busca automaticamente pelo ponto de entrada (`main.kaz` ou `src/main.kaz`) e compila todo o grafo de dependências e submódulos:
```bash
# Executa o projeto localizado na pasta 'meu_sistema':
kaz meu_sistema/

# Executa o projeto localizado na pasta atual:
kaz .
```

### C. Criar um Novo Projeto Estruturado (`kaz new` ou `kaz create`)
Para iniciar um novo projeto com a arquitetura padrão recomendada (com banco SQLite embutido, modelos, testes automatizados e manifesto `kaz.json`):

```bash
kaz new meusistema
# ou equivalentemente:
kaz create meusistema
```

O comando gera a seguinte árvore:
```text
meusistema/
├── kaz.json             # Manifesto de configuração do projeto
├── README.md            # Documentação e instruções de execução
├── .gitignore           # Ignora *.db, bin/, dist/ e temporários
├── data/
│   └── schema.sql       # Script DDL com a estrutura do banco SQLite
├── src/
│   ├── main.kaz         # Ponto de entrada do sistema
│   ├── database.kaz     # Funções utilitárias de conexão e migração SQLite
│   └── models/
│       └── usuario.kaz  # Modelos de domínio (structs)
└── tests/
    └── main_test.kaz    # Testes unitários automatizados nativos
```

Para rodar e testar imediatamente:
```bash
cd meusistema
kaz run .
kaz test
```

---

## 3. Motores de Execução (JIT Nativo vs Stack VM vs AST)

Kaz possui três motores de execução de alta fidelidade:

### 1. Compilador JIT Nativo via Cranelift (`kaz jit`) ⚡
Compila o código-fonte em tempo de execução diretamente para **código de máquina AMD64 nativo**, oferecendo desempenho de até **~750x mais rápido que a interpretação em Bytecode**, e rodando a 1.9x de paridade com Rust/C compilados com otimização máxima (`-O3`):
```bash
kaz jit programa.kaz
# Passando argumentos via linha de comando:
kaz jit programa.kaz arg1 arg2
```

### 2. Stack Bytecode Virtual Machine (Padrão Portável)
Compila o código para sequências contíguas de `OpCode` em memória e despacha instruções em alta velocidade na VM:
```bash
kaz programa.kaz
# ou explicitamente:
kaz run programa.kaz
```

### 3. AST Tree-Walking Evaluator (Modo Clássico / Fallback)
Modo alternativo para depuração e inspeção detalhada de nós da Árvore Sintática:
```bash
kaz ast programa.kaz
```

---

## 4. Compilação de Binários Autônomos (`kaz build`) 📦

Kaz é capaz de compilar e empacotar scripts e projetos em **executáveis nativos autônomos** com **zero dependências externas**:

### A. Gerar Executável Autônomo (.exe no Windows, ELF no Linux)
```bash
kaz build main.kaz -o meu_app.exe
# Executa diretamente em qualquer máquina sem precisar do runtime instalado:
.\meu_app.exe
```

### B. Gerar Arquivo de Objeto Nativo (.obj no Windows, .o no Linux)
Gera arquivos de código de máquina compilados diretamente pelo Cranelift para integração com linkers externos como MSVC link.exe ou GNU ld:
```bash
kaz build main.kaz --emit-obj -o main.obj
```

---

## 4. Validação de Sintaxe (Check)

Para verificar se um código ou projeto possui erros de sintaxe **sem executar nenhuma instrução**:
```bash
kaz check programa.kaz
# ou em um projeto:
kaz check meu_projeto/
```

**Saída em caso de sucesso:**
```text
Sintaxe correta: 'meu_projeto/main.kaz' verificado com sucesso!
```

---

## 5. Formatador Canônico de Código (`kaz fmt`) 📐

Kaz possui um formatador de código automático integrado de nível de produção (`kaz fmt`), eliminando discussões de estilo e padronizando todo o ecossistema.

### Características do Estilo Canônico Kaz:
- **Indentação consistente**: 4 espaços por nível.
- **Estilo de Chaves K&R / 1TBS**: Chaves de abertura na mesma linha (`function Main() {`, `if (cond) { ... } else { ... }`, `try { ... } catch (e) { ... }`).
- **Espaçamento de Operadores**: Espaçamento uniforme em operadores binários (`+`, `-`, `*`, `/`, `%`), de atribuição (`=`, `+=`, `-=`, `*=`, `/=`, `%=`), relacionais (`==`, `!=`, `<`, `>`, `<=`, `>=`), lógicos (`&&`, `||`) e ternários (`? :`).
- **Operadores Unários Compactos**: Operadores `+`, `-` e `!` unários aderem imediatamente ao operando (`-5`, `+3`, `!ativo`).
- **Parâmetros e Argumentos**: Vírgula seguida de espaço uniforme (`function soma(int a, int b): int`).
- **Colapso de Linhas em Branco**: Evita acúmulo desnecessário de quebras de linha (máximo de 1 linha em branco consecutiva entre instruções ou declarações).
- **Preservação Total de Comentários**: Comentários de linha (`//`) e comentários em bloco (`/* ... */`) são fielmente preservados.
- **🛡️ Garantia de Segurança por Validação de AST**: Antes de gravar qualquer alteração em disco, o compilador Kaz analisa a Árvore Sintática Abstrata (AST) do arquivo formatado e a compara com o original. Se houver qualquer divergência sintática, a formatação é abortada imediatamente com erro explicativo, garantindo que o seu código nunca será corrompido.

### Modos de Uso:

#### A. Formatar um Arquivo Específico
```bash
kaz fmt src/main.kaz
```

#### B. Formatar um Diretório ou Projeto Recursivamente
```bash
# Formata recursivamente todos os arquivos .kaz dentro da pasta src/
kaz fmt src/

# Formata recursivamente todo o projeto atual
kaz fmt .
```

#### C. Modo Verificação (`--check`) para CI/CD Pipelines
Verifica se todos os arquivos estão em conformidade com o padrão sem modificar o disco. Retorna código de saída `0` se tudo estiver perfeito ou `1` se houver arquivos precisando de formatação:
```bash
kaz fmt src/ --check
```

---

## 6. Kaz Terminal Interativo (Shell)

O **Kaz Terminal** combina os recursos de um shell de sistema operacional com o interpretador em tempo real da linguagem:

```bash
kaz shell
# ou simplesmente iniciar kaz sem argumentos:
kaz
```

### Interface do Kaz Terminal:
```text
╔═════════════════════════════════════════════════════════════════╗
║                      KAZ TERMINAL 🦅 v1.1.0                     ║
║              Ambiente Interativo & Shell da Linguagem           ║
╚═════════════════════════════════════════════════════════════════╝

kaz [E:\projetos]> ls
  [DIR]  models/
  [DIR]  db/
  [FILE] main.kaz (1.5 KB)

kaz [E:\projetos]> int a = 10;
kaz [E:\projetos]> int b = 25;
kaz [E:\projetos]> runoff("Soma:", a + b);
=> Soma: 35

kaz [E:\projetos]> run main.kaz
[Executa a aplicação modular e preserva variáveis de sessão]
```

### Comandos Embutidos do Shell:
- `ls` / `dir`: Lista arquivos e diretórios detalhando tamanhos.
- `cd <pasta>`: Navega entre diretórios e atualiza o prompt dinamicamente.
- `pwd`: Exibe o diretório de trabalho atual.
- `run <arquivo>`: Executa um script Kaz diretamente na sessão ativa.
- `check <arquivo>`: Valida a sintaxe de um script.
- `fmt [caminho]`: Formata scripts ou diretórios no padrão canônico Kaz.
- `env`: Exibe todas as variáveis, funções e tipos ativos no escopo do shell.
- `clear` / `cls`: Limpa a tela do terminal.
- `help`: Mostra o manual de comandos rápidos.
- `exit` / `quit`: Encerra o Kaz Terminal.

---

## 7. Executor de Testes Nativos (`kaz test`) 🧪

Kaz traz um executor de testes unitários integrado diretamente no compilador. Não é necessário baixar nenhuma ferramenta de terceiros:

```bash
# Executa todos os testes do projeto na pasta atual:
kaz test

# Executa testes em uma pasta específica:
kaz test tests/

# Executa testes contidos em um único arquivo:
kaz test meu_arquivo.kaz
```

### Relatório Visual do Teste:
```text
running 2 test(s) in examples/battery_included_demo.kaz:
  test "validar integridade de sha256"          ... ok (1.22ms)
  test "validar regex simples"                  ... ok (1.21ms)

test result: OK. 2 passed; 0 failed; finished in 3.54ms
```

---

## 8. Ferramentas de Diagnóstico e Debug Nativas 🔍

### A. Rastreamento Passo a Passo da Stack VM (`kaz trace`)
Permite inspecionar o ciclo de vida da Máquina Virtual em tempo real, exibindo o Ponteiro de Instrução (IP), a Linha do Código (L), o OpCode despachado e o estado exato da Pilha de Valores:

```bash
kaz trace programa.kaz
```

**Exemplo de Saída:**
```text
=== Kaz Stack VM Tracer: Iniciando rastreamento de 'programa.kaz' ===

[TRACE IP:0000 L002] Constant(0)               | Pilha (0): []
[TRACE IP:0001 L002] DefGlobal(1, false, Int)  | Pilha (1): [Int(10)]
[TRACE IP:0002 L003] GetGlobal(1)              | Pilha (0): []
[TRACE IP:0003 L003] Constant(2)               | Pilha (1): [Int(10)]
[TRACE IP:0004 L003] Add                       | Pilha (2): [Int(10), Int(20)]
[TRACE IP:0005 L003] CallNative(3, 1)          | Pilha (1): [Int(30)]
30
[TRACE IP:0006 L003] Pop                       | Pilha (1): [Void]
[TRACE IP:0007 L001] Halt                      | Pilha (0): []

=== Rastreamento finalizado ===
```

### B. Desmontador de Bytecode & Constantes (`kaz debug`)
Desmonta os chunks de bytecode compilados e exibe a tabela de literais e instruções sem executar o programa:

```bash
kaz debug programa.kaz
```

### C. Console SQL Interativo do SQLite (`kaz db-cli`)
Abre um terminal interativo conectado diretamente a qualquer arquivo de banco de dados SQLite, permitindo rodar consultas e comandos de inspeção sem instalar clientes externos:

```bash
kaz db-cli meu_banco.db
```

**Comandos do `kaz db-cli`:**
- `.tables`: Lista todas as tabelas criadas no banco de dados.
- `.schema [tabela]`: Exibe a instrução DDL de criação da tabela.
- `SELECT ...`: Executa consultas e exibe o resultado formatado em colunas.
- `INSERT` / `UPDATE` / `DELETE`: Executa alterações e exibe o número de linhas afetadas.
- `.exit` ou `.quit`: Encerra o console do banco.

---

## 9. REPL Simples

Para testes rápidos de expressões aritméticas ou snippets curtos de código:
```bash
kaz repl
```

---

## 10. Referência de Opções e Códigos de Saída

### Tabela Geral de Comandos da CLI:
| Comando | Descrição |
|---|---|
| `kaz <caminho>` | Executa arquivo `.kaz` ou pasta de projeto na Bytecode VM. |
| `kaz run <caminho>` | Sinônimo explícito de execução na VM. |
| `kaz test [caminho]` | Executa os blocos de testes unitários nativos com relatório. |
| `kaz trace <arquivo>` | Rastreia a Stack VM passo a passo exibindo a pilha em tempo real. |
| `kaz debug <arquivo>` | Desmonta o bytecode e exibe as tabelas de constantes e chunks. |
| `kaz db-cli <banco.db>` | Abre o console interativo SQL para o banco SQLite embutido. |
| `kaz vm <caminho>` | Força execução na Bytecode VM. |
| `kaz ast <caminho>` | Executa no interpretador clássico de AST. |
| `kaz check <caminho>` | Valida sintaxe sem executar. |
| `kaz fmt [caminho] [--check]` | Formata arquivos .kaz no estilo canônico (--check para CI/CD). |
| `kaz shell` / `kaz` | Inicia o Kaz Terminal Shell interativo. |
| `kaz repl` | Inicia o REPL simplificado. |
| `kaz --help` / `-h` | Exibe a mensagem de ajuda e opções. |
| `kaz --version` / `-v` | Exibe a versão instalada da linguagem. |

### Códigos de Saída (Exit Codes):
| Código | Significado |
|---|---|
| `0` | Execução concluída com sucesso (ou todos os testes passaram / formatado). |
| `1` | Erro de sintaxe, asserção falha, runtime, arquivo não encontrado ou formatação pendente em `--check`. |


