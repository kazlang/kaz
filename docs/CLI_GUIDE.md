# Manual da CLI & Kaz Terminal 🖥️

O utilitário de linha de comando `kaz` é o coração do ecossistema da linguagem, fornecendo ferramentas para executar scripts, gerenciar projetos em pastas, validar código e utilizar o **Kaz Terminal Interativo**.

---

## 📑 Sumário

1. [Instalação & Configuração de PATH](#1-instalação--configuração-de-path)
2. [Execução de Arquivos e Projetos](#2-execução-de-arquivos-e-projetos)
3. [Modos de Execução (VM vs AST)](#3-modos-de-execução-vm-vs-ast)
4. [Validação de Sintaxe (Check)](#4-validação-de-sintaxe-check)
5. [Kaz Terminal Interativo (Shell)](#5-kaz-terminal-interativo-shell)
6. [REPL Simples](#6-repl-simples)
7. [Referência de Opções e Códigos de Saída](#7-referência-de-opções-e-códigos-de-saída)

---

## 1. Instalação & Configuração de PATH

Após executar o instalador (`install.ps1` no Windows ou `install.sh` no Linux/macOS), o binário `kaz` fica disponível em qualquer terminal:

```bash
kaz --version
# Kaz 1.0.0
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

---

## 3. Modos de Execução (VM vs AST)

Kaz possui dois motores de execução internos:

### 1. Stack Bytecode Virtual Machine (Padrão de Alta Performance)
O motor padrão compila o código para sequências contíguas de `OpCode` em memória e despacha instruções em alta velocidade:
```bash
kaz programa.kaz
# ou
kaz vm programa.kaz
```

### 2. AST Tree-Walking Evaluator (Modo Clássico / Fallback)
Modo alternativo para depuração e inspeção detalhada de nós da Árvore Sintática:
```bash
kaz ast programa.kaz
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

## 5. Kaz Terminal Interativo (Shell)

O **Kaz Terminal** combina os recursos de um shell de sistema operacional com o interpretador em tempo real da linguagem:

```bash
kaz shell
# ou simplesmente iniciar kaz sem argumentos:
kaz
```

### Interface do Kaz Terminal:
```text
╔═════════════════════════════════════════════════════════════════╗
║                      KAZ TERMINAL 🦅 v1.0.0                     ║
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
- `env`: Exibe todas as variáveis, funções e tipos ativos no escopo do shell.
- `clear` / `cls`: Limpa a tela do terminal.
- `help`: Mostra o manual de comandos rápidos.
- `exit` / `quit`: Encerra o Kaz Terminal.

---

## 6. REPL Simples

Para testes rápidos de expressões aritméticas ou snippets curtos de código:
```bash
kaz repl
```

---

## 7. Referência de Opções e Códigos de Saída

### Tabela de Comandos da CLI:
| Comando | Descrição |
|---|---|
| `kaz <caminho>` | Executa arquivo `.kaz` ou pasta de projeto na Bytecode VM. |
| `kaz run <caminho>` | Sinônimo explícito de execução. |
| `kaz vm <caminho>` | Força execução na Bytecode VM. |
| `kaz ast <caminho>` | Executa no interpretador clássico de AST. |
| `kaz check <caminho>` | Valida sintaxe sem executar. |
| `kaz shell` / `kaz` | Inicia o Kaz Terminal Shell interativo. |
| `kaz repl` | Inicia o REPL simplificado. |
| `kaz --help` / `-h` | Exibe a mensagem de ajuda e opções. |
| `kaz --version` / `-v` | Exibe a versão instalada da linguagem. |

### Códigos de Saída (Exit Codes):
| Código | Significado |
|---|---|
| `0` | Execução concluída com sucesso. |
| `1` | Erro de sintaxe, tipo, runtime ou arquivo não encontrado. |
