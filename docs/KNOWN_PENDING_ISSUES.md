# Kaz Language: Known Pending Issues Drawer System

This document categorizes all remaining architectural, robustness, and performance improvements across the Kaz compiler and runtimes (AST Evaluator, Bytecode VM, and x86-64 Native AOT).

Each pending item is filed into one of four prioritized drawers.

---

## Drawer 1: Security & Memory Architecture (High Priority)

### [1.1] External Binary Model Format Validation (Safetensors & .kzm)
- **Status**: Partially completed in VM; strict arithmetic overflow checks in AOT pending.
- **Description**:
  When reading binary model files (.safetensors or .kzm), tensor data offsets and shapes must be checked against the mapped file length (`mmap_len`).
- **Required Implementation**:
  1. Arithmetic overflow validation: verify `data_offset.checked_add(data_len) <= file_len`.
  2. Strict header size ceiling: enforce maximum JSON header size (e.g. 100 MB) to prevent denial of service during initial model parse.
  3. Tensor dimension validation: verify that dimension product calculation does not overflow 64-bit integers.

---

## Drawer 2: Types, Robustness & Compatibility

### [2.1] Complete Standard Library Parity in AOT (libkazrt / FFI)
- **Status**: Partial parity.
- **Description**:
  The Bytecode VM supports database access (`db_open`, `db_query`, SQLite), crypto (`sha256`, `md5`, `base64`, `random_bytes`, `const_time_equal`), regular expressions (`regex_find`, `regex_replace`), and JSON (`json_parse`, `json_stringify`).
  The AOT backend currently includes native I/O, file operations, cryptographic primitives, floating point formatting, exact decimal arithmetic, and raw buffers.
- **Required Implementation**:
  1. Package `runtime/kazrt.c` into a modular static runtime library (`libkazrt.a`).
  2. Implement SQLite and regex C FFI wrappers to link against AOT binaries on demand.
  3. Unify JSON serialization across VM and AOT.

---

## Drawer 3: Medium Priority (Architecture & Optimization)

### [3.1] $O(1)$ Value Semantics in Bytecode VM (`Rc<RefCell<...>>`)
- **Status**: Planned.
- **Description**:
  Currently, `OpCode::GetLocal` and `Value::clone()` deep-clone complex structures (`Vec<Value>` for arrays). In tight loops, this causes $O(N^2)$ copying overhead.
- **Required Implementation**:
  Adopt `Rc<RefCell<Vec<Value>>>` and `Rc<RefCell<HashMap<...>>>` for compound values in the VM, achieving true $O(1)$ shallow copying and reference sharing.

### [3.2] Length-Prefixed UTF-8 Strings (`{len, ptr}`)
- **Status**: Planned.
- **Description**:
  Strings in AOT currently use C-style null-terminated pointers.
- **Required Implementation**:
  Migrate string representation to `{len: u64, ptr: *const u8}`:
  - Supports arbitrary binary data containing null bytes (`\0`).
  - Mitigates null-injection path traversal vulnerabilities.
  - Guarantees $O(1)$ string length calculation.

### [3.3] Explicit Pass-by-Reference (`ref`)
- **Status**: Planned.
- **Description**:
  Passing large structs or tensors currently relies on copying or ad-hoc global buffers.
- **Required Implementation**:
  Introduce the `ref` modifier in function signatures:
  ```kaz
  function compute(ref Tensor t, ref Matrix m): void { ... }
  ```
  Guarantees zero-copy parameter passing.

---

## Drawer 4: Long Term & Complete Self-Sufficiency

### [4.1] Path Confinement (`fs.resolve_within`)
- **Status**: Planned.
- **Description**:
  Provide an explicit sandbox API `fs.resolve_within(base_dir, relative_path)` that canonicalizes paths and verifies that relative traversal (`../`) cannot escape `base_dir`.

### [4.2] Canonical Parser Unification
- **Status**: Planned.
- **Description**:
  Currently, Kaz maintains a Pest grammar for the bootstrap Rust compiler and a hand-crafted Pratt parser for the self-hosted Kaz compiler (`compiler/parser.kaz`).
  Unifying them into a single canonical grammar ensures zero drift between bootstrap and stage2.

### [4.3] Direct Machine Code Generation (Eliminating NASM and GNU ld)
- **Status**: Long-term research.
- **Description**:
  Replace external dependencies (`nasm` assembler and `ld` linker) with an in-tree x86-64 machine code encoder and direct ELF-64 binary writer, achieving 100% freestanding self-sufficiency.
