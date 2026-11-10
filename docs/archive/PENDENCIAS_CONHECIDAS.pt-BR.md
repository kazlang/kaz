# Linguagem Kaz: Sistema de Gavetas de Pendências Conhecidas

Este documento categoriza e organiza todas as melhorias arquiteturais, de robustez e de desempenho remanescentes no compilador Kaz e em seus runtimes (Avaliador AST, Bytecode VM e Nativo AOT x86-64).

Cada item pendente está catalogado em uma de quatro gavetas priorizadas.

---

## Gaveta 1: Segurança e Arquitetura de Memória (Alta Prioridade)

### [1.1] Validação Estrita de Formatos Binários Externos (Safetensors e .kzm)
- **Status**: Concluído ✅ (Implementado na VM e AOT com checagem de overflow aritmético e testes em `tests/model_validation_tests.rs`).
- **Descrição**:
  Ao carregar arquivos de modelos binários (.safetensors ou .kzm), os deslocamentos (`data_offsets`) e formatos dos tensores são rigorosamente validados contra o tamanho real mapeado em memória (`mmap_len`), prevenindo estouro de inteiros de 64 bits e ataques DoS.

---

## Gaveta 2: Tipos, Robustez e Compatibilidade

### [2.1] Paridade Completa da Biblioteca Padrão no AOT (libkazrt / FFI)
- **Status**: Paridade parcial.
- **Descrição**:
  A VM Bytecode possui suporte a banco de dados (`db_open`, `db_query`, SQLite), criptografia (`sha256`, `md5`, `base64`, `random_bytes`, `const_time_equal`), expressões regulares (`regex_find`, `regex_replace`) e JSON (`json_parse`, `json_stringify`).
  O backend AOT atualmente contempla E/S nativa, arquivos, primitivos criptográficos essenciais, formatação de ponto flutuante, aritmética decimal exata e buffers brutos.
- **Implementação Necessária**:
  1. Empacotar `runtime/kazrt.c` como biblioteca estática modular (`libkazrt.a`).
  2. Implementar wrappers C/FFI para SQLite e regex ligáveis aos binários AOT sob demanda.
  3. Unificar serialização JSON entre VM e AOT.

---

## Gaveta 3: Média Prioridade (Arquitetura e Otimização)

### [3.1] Semântica de Valores $O(1)$ na VM Bytecode (`Rc<RefCell<...>>`)
- **Status**: Planejado.
- **Descrição**:
  Atualmente, `OpCode::GetLocal` e `Value::clone()` realizam cópias profundas de estruturas compostas (`Vec<Value>` para arrays). Em laços intensos, isso gera sobrecarga $O(N^2)$.
- **Implementação Necessária**:
  Adotar `Rc<RefCell<Vec<Value>>>` e `Rc<RefCell<HashMap<...>>>` para valores compostos na VM, garantindo clonagem e compartilhamento $O(1)$.

### [3.2] Strings com Tamanho Explícito (`{len, ptr}`)
- **Status**: Planejado.
- **Descrição**:
  Strings no AOT atualmente usam ponteiros terminados em nulo estilo C.
- **Implementação Necessária**:
  Migrar a representação de strings para `{len: u64, ptr: *const u8}`:
  - Suporte completo a dados binários arbitrários contendo bytes nulos (`\0`).
  - Mitigação de injeção de nulo em caminhos de arquivo.
  - Cálculo de tamanho em tempo $O(1)$.

### [3.3] Passagem por Referência Explícita (`ref`)
- **Status**: Planejado.
- **Descrição**:
  A passagem de tensores e grandes structs atualmente requer cópia de valores ou uso de buffers globais.
- **Implementação Necessária**:
  Introduzir o modificador `ref` na assinatura de funções:
  ```kaz
  function compute(ref Tensor t, ref Matrix m): void { ... }
  ```
  Garante passagem com zero cópia de parâmetros.

---

## Gaveta 4: Longo Prazo e Autossuficiência Completa

### [4.1] Confinamento de Caminhos (`fs.resolve_within`)
- **Status**: Planejado.
- **Descrição**:
  Expor API de sandbox `fs.resolve_within(base_dir, relative_path)` que canonicaliza caminhos e impede que navegação relativa (`../`) escape do diretório base.

### [4.2] Unificação do Parser Canônico
- **Status**: Planejado.
- **Descrição**:
  Atualmente, Kaz mantém uma gramática Pest para o compilador Rust de bootstrap e um parser Pratt manual para o compilador self-hosted (`compiler/parser.kaz`).
  A unificação garante paridade gramatical sem divergências entre bootstrap e stage2.

### [4.3] Emissão Direta de Código de Máquina (Substituindo NASM e GNU ld)
- **Status**: Pesquisa de longo prazo.
- **Descrição**:
  Substituir o montador NASM e o ligador ld por um codificador x86-64 nativo e escritor direto de arquivos ELF-64, atingindo autossuficiência 100% independente.
