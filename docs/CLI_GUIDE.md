# CLI & Kaz Terminal Guide 🖥️

The `kaz` command-line interface is the core utility of the Kaz ecosystem, providing tools to execute scripts, manage multi-file projects, validate code, and interact with the **Kaz Interactive Shell**.

---

## 📑 Table of Contents

1. [Installation & PATH Configuration](#1-installation--path-configuration)
2. [Running Scripts and Projects](#2-running-scripts-and-projects)
3. [Execution Modes (Stack VM vs AST)](#3-execution-modes-stack-vm-vs-ast)
4. [Standalone Native Compilation (`kaz build`)](#4-standalone-native-compilation-kaz-build-)
5. [Syntax Validation (`kaz check`)](#5-syntax-validation-kaz-check)
6. [Canonical Code Formatter (`kaz fmt`)](#6-canonical-code-formatter-kaz-fmt)
7. [Interactive Kaz Terminal (Shell)](#7-interactive-kaz-terminal-shell)
8. [Native Test Runner (`kaz test`)](#8-native-test-runner-kaz-test)
9. [Diagnostic and Debug Tools](#9-diagnostic-and-debug-tools)
10. [Simple REPL](#10-simple-repl)
11. [Command Reference & Exit Codes](#11-command-reference--exit-codes)

---

## 1. Installation & PATH Configuration

After running the official installer (`install.ps1` on Windows or `install.sh` on Linux/macOS), the `kaz` binary is accessible globally in any terminal:

```bash
kaz --version
# Output: Kaz 1.5.0
```

To verify the installation and view quick help:
```bash
kaz --help
```

---

## 2. Running Scripts and Projects

### 2.1 Single File Execution
To run an individual script via the Stack VM (default mode):
```bash
kaz run script.kaz
# Or simply:
kaz script.kaz
```

### 2.2 Passing Command-Line Arguments
Arguments passed after the filename are forwarded directly to the script and accessible through the standard library `io.args()`:
```bash
kaz run script.kaz arg1 arg2 "third argument"
```

### 2.3 Running Structured Projects (`main.kaz`)
When pointing `kaz run` to a directory containing a `main.kaz` entrypoint:
```bash
kaz run ./meu_projeto
```
The runtime automatically resolves dependencies, imports, and executes `main.kaz`.

---

## 3. Execution Modes (Stack VM vs AST)

Kaz offers two execution engines:

| Engine | Flag | Description | Ideal For |
| :--- | :--- | :--- | :--- |
| **Stack VM** | *(default)* | Compiles to bytecode and executes on an optimized Stack Virtual Machine. | Production, high performance, enterprise workloads. |
| **AST Tree-Walk** | `--ast` | Directly walks the Abstract Syntax Tree. | Educational debugging, compiler development. |

Example:
```bash
# High-performance execution via Stack VM (default)
kaz run benchmark.kaz

# Tree-walk execution
kaz run --ast benchmark.kaz
```

---

## 4. Standalone Native Compilation (`kaz build`) 📦

Kaz can compile source files directly into **standalone, pure x86-64 ELF64 binaries** (~10 KB) with zero external runtime dependencies (no libc, no VM):

```bash
# Compile directly to a standalone binary
kaz build main.kaz -o my_app

# Run the compiled native binary directly
./my_app
```

### Build Options:
- `-o <output>`: Specifies the output executable name.
- `--emit-asm`: Emits clean Intel-syntax NASM assembly code without linking.
- `--emit-obj`: Emits the ELF64 object file (`.o`).

---

## 5. Syntax Validation (`kaz check`)

Performs lexical and syntactic verification without executing the code. Useful for CI/CD pipelines, pre-commit hooks, and IDE integration:

```bash
kaz check script.kaz
```

Output:
```text
✓ Syntax OK: script.kaz
```

In case of syntax errors, the command exits with code `1` and prints the exact line, column, and error context.

---

## 6. Canonical Code Formatter (`kaz fmt`)

Formats `.kaz` files according to official style guidelines with AST round-trip validation:

```bash
# Format a specific file in place
kaz fmt script.kaz

# Check formatting without modifying (CI mode)
kaz fmt --check script.kaz

# Format all .kaz files in the current folder recursively
kaz fmt .
```

---

## 7. Interactive Kaz Terminal (Shell)

Launches the rich interactive shell with syntax highlighting, auto-completion, multiline editing, and command history:

```bash
kaz shell
```

Special shell commands:
- `:help`: Displays available commands.
- `:vars`: Lists active variables and structs in scope.
- `:clear`: Clears the terminal screen.
- `:reset`: Resets the execution environment state.
- `:exit` / `quit`: Exits the terminal.

---

## 8. Native Test Runner (`kaz test`)

Discovers and executes built-in test suites defined with `test "name" { ... }`:

```bash
# Run all tests in the current project
kaz test

# Run tests matching a specific pattern
kaz test --filter "auth"
```

---

## 9. Diagnostic and Debug Tools

Kaz includes native diagnostics for inspecting compilation phases:

### 9.1 Disassembling Bytecode
```bash
kaz --disasm script.kaz
```
Prints the complete disassembled bytecode instruction table with operands, jumps, and string pools.

### 9.2 Inspecting the AST
```bash
kaz --dump-ast script.kaz
```
Outputs the formatted syntax tree hierarchy for debugging parser behaviors.

---

## 10. Simple REPL

For quick expression evaluation and lightweight interactive sessions without terminal styling:
```bash
kaz repl
```

---

## 11. Command Reference & Exit Codes

| Command | Description |
| :--- | :--- |
| `kaz run <file> [args]` | Executes a Kaz script or project using the Stack VM. |
| `kaz build <file> [-o bin]` | Compiles a program to a native standalone x86-64 executable. |
| `kaz check <file>` | Validates syntax and types without execution. |
| `kaz fmt <file\|dir>` | Formats code to official canonical style. |
| `kaz shell` | Opens the rich interactive terminal. |
| `kaz repl` | Opens the lightweight REPL. |
| `kaz test [path]` | Executes test suites. |
| `kaz --version` | Displays version and build info. |
| `kaz --help` | Displays command-line help. |

### Exit Codes:
- `0`: Success.
- `1`: Syntax or compilation error.
- `2`: Runtime error or uncaught exception.
- `130`: Terminated by user (`SIGINT` / `Ctrl+C`).
