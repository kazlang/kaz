# Relatório de Conclusão: Milestone 3 - Compilador Kaz Self-Hosted 🦅

**Data:** 06 de Outubro de 2026  
**Status:** Concluído com Sucesso Absoluto (Bit-for-Bit Idêntico / SHA-256 Validado)  
**Ambiente:** Linux x86-64 / Compatível com Windows x86-64  

---

## 1. Sumário Executivo

O **Milestone 3** do projeto da Linguagem Kaz foi oficialmente concluído. A linguagem Kaz alcançou o ápice do ciclo de vida de uma linguagem de programação: **a auto-hospedagem (self-hosting)**.

O compilador Kaz escrito integralmente em código Kaz (`compiler/*.kaz`) compilou o seu próprio código-fonte, gerando o executável de bytecode `kazc.kzc`. Em seguida, na **Compilação Triangular (Milestone 3.4)**, o próprio binário `kazc.kzc` compilou novamente o código-fonte gerando `kazc_v2.kzc`. Os checksums criptográficos SHA-256 de ambos os arquivos gerados foram **100% idênticos, bit a bit**.

```
                         [ compiler/main.kaz ]
                                   │
               ┌───────────────────┴───────────────────┐
               ▼                                       ▼
    (1) kaz (Rust VM)                       (2) kazc.kzc (Kaz VM)
               │                                       │
               ▼                                       ▼
          [ kazc.kzc ]                            [ kazc_v2.kzc ]
               │                                       │
               └───────────────► SHA-256 ◄─────────────┘
                               06cd8e2ce...
                              (100% IDÊNTICO)
```

---

## 2. Resultados das Etapas do Milestone 3

| Etapa | Descrição | Status | Resultado |
| :--- | :--- | :---: | :--- |
| **Milestone 3.1** | Pipeline Léxico e Sintático Self-Hosted | ✅ Concluído | Lexer e Pratt Parser processando 22.387 tokens e 9.072 nós de AST |
| **Milestone 3.2** | Geração de Bytecode e Serialização `.kzc` | ✅ Concluído | Tabela de funções serializada em formato binário compacto (`103.277` bytes) |
| **Milestone 3.3** | Bootstrap do Compilador (`kazc.kzc`) | ✅ Concluído | `kaz run compiler/main.kaz compiler/main.kaz kazc.kzc` com código 0 |
| **Milestone 3.4** | Compilação Triangular e Verificação SHA-256 | ✅ Concluído | `kazc.kzc compiler/main.kaz kazc_v2.kzc` idêntico a `kazc.kzc` |

---

## 3. Principais Problemas Diagnosticados e Soluções de Engenharia

### 3.1. Dessincronização de Pilha por Literais Booleanos no Codegen
* **Sintoma:** Falha em tempo de execução `GetLocal: slot 6 fora dos limites` durante a leitura de tokens numéricos (`'2'`).
* **Causa Raiz:** No arquivo `compiler/lexer.kaz`, na linha 135 havia `bool is_float = false;`. O `compiler/codegen.kaz` não possuía tratamento para `ExprKind::LiteralBool` em `codegen_compile_expr`. Portanto, em tempo de compilação, a variável `is_float` era registrada em `ctx.locals`, mas em tempo de execução **nenhum valor era empilhado**. Ao encontrar o `continue` do loop, o compilador calculava `to_pop = ctx.locals.len - cur_loop.locals_count` e desempilhava da pilha física um valor a mais (eliminando a variável `tokens` e corrompendo a base do frame).
* **Solução:** Implementação de `chunk_add_bool`, `chunk_find_bool` e suporte nativo a `LiteralBool`, `LiteralNull` e `LiteralChar` no `compiler/bytecode.kaz` e `compiler/codegen.kaz`.

### 3.2. Perda de Caminho por Passagem de Array por Valor (`parser_extract_assign_path`)
* **Sintoma:** Erro de tipo em tempo de execução `Tipo 'int' não suporta acesso a campos` no `parser_advance`.
* **Causa Raiz:** Como Kaz possui semântica de cópia por valor para estruturas e arrays, passar `array[int] path` para a função `parser_extract_assign_path` fazia com que o `path.push(...)` ocorresse em uma cópia local. Ao retornar, o chamador ficava com `path.len == 0`. Como consequência, `state.current = state.current + 1;` era compilado como uma atribuição simples à raiz `state = state.current + 1`, sobrescrevendo a struct com um número inteiro.
* **Solução:** Desacoplamento do caminho de atribuição para o array global `array[int] g_assign_path = [];`, eliminando qualquer distorção de cópia por valor.

### 3.3. O(1) PushGlobal e Desacoplamento de Arenas no Pratt Parser
* **Sintoma:** O Pratt Parser aninhado consumia tempos exorbitantes por causa da passagem de struct de estado por valor contendo dezenas de milhares de tokens.
* **Solução:** Desacoplamento das arenas da AST (`g_expr_arena`, `g_stmt_arena`, `g_parser_tokens`) para variáveis globais acessadas em O(1), e criação do OpCode `PushGlobal` no runtime, reduzindo o tempo de compilação de minutos para ~1,5 segundo.

---

## 4. Guia de Execução no Windows (Quando Alternar de SO)

Quando você estiver no Windows, utilize o PowerShell ou Prompt de Comando na raiz do projeto (`C:\ProjetosAM\kaz` ou caminho correspondente):

### Compilar o Binário do Kaz VM (Rust)
```powershell
cargo build --release
```

### Rodar os Testes Unitários e de Integração
```powershell
cargo test --release
```

### Gerar um Novo `kazc.kzc` a partir do Fonte
```powershell
.\target\release\kaz.exe run compiler\main.kaz compiler\main.kaz kazc.kzc
```

### Compilar um Programa Kaz Usando o Compilador Self-Hosted
```powershell
.\target\release\kaz.exe run kazc.kzc tests\meu_programa.kaz saida.kzc
```

### Executar o Bytecode Compilado
```powershell
.\target\release\kaz.exe run saida.kzc
```

### Executar a Compilação Triangular no Windows
```powershell
# Compila o próprio compilador usando o binário já compilado:
.\target\release\kaz.exe run kazc.kzc compiler\main.kaz kazc_v2.kzc

# Comparar os hashes (devem ser idênticos):
Get-FileHash kazc.kzc, kazc_v2.kzc -Algorithm SHA256
```

---

## 5. Checksum Oficial de Referência

* **Arquivo:** `kazc.kzc` / `kazc_v2.kzc`
* **Tamanho:** 103.277 bytes (84 funções de usuário)
* **SHA-256:**
  ```text
  06cd8e2ce981ace55927ed8ad6fcd05528713da5618a708fdbbd5b8a8bb99750
  ```
