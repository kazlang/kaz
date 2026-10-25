# Official Kaz Language Guide 🦅

Welcome to the comprehensive reference guide for the **Kaz** programming language.  
Kaz is a modern, strongly typed, expressive, and high-performance language engineered to combine clean syntax with the robustness of compilation for both a **Stack-Based Bytecode Virtual Machine (Stack VM)** and direct **Native AOT x86-64 Machine Code Generation**.

---

## 📑 Table of Contents

1. [Overview & Philosophy](#1-overview--philosophy)
2. [Basic Syntax & Comments](#2-basic-syntax--comments)
3. [Type System & Literals](#3-type-system--literals)
4. [Variables, Constants, and Scoping](#4-variables-constants-and-scoping)
5. [Operators & Expressions](#5-operators--expressions)
   - [Arithmetic, Relational, and Logical](#arithmetic-relational-and-logical)
   - [Ternary Operator (? :)](#ternary-operator)
6. [Control Flow](#6-control-flow)
   - [Conditionals (if, else if, else)](#conditionals)
   - [Modern for..in Loop](#modern-for-in-loop)
   - [Traditional while Loop](#traditional-while-loop)
7. [Functions & Closures](#7-functions--closures)
8. [Structs & OOP Features](#8-structs--oop-features)
9. [Error Handling (try / catch)](#9-error-handling-try--catch)
10. [Built-in Native Testing (`test`)](#10-built-in-native-testing-test)
11. [Module System & Imports](#11-module-system--imports)

---

## 1. Overview & Philosophy

Kaz is designed with three core pillars:
- **Ergonomics & Readability**: Clean, Rust- and TypeScript-inspired syntax without visual noise.
- **Type Safety**: Strong static typing preventing subtle runtime crashes.
- **Maximum Performance**: Zero-overhead VM execution and standalone native machine code generation.

---

## 2. Basic Syntax & Comments

```rust
// Single-line comment

/*
   Multi-line comment block
*/

println("Hello, Kaz World!");
```

Statements can end with an optional semicolon `;`.

---

## 3. Type System & Literals

Kaz features strong primitive types, exact fixed-point decimals, and rich composite types:

| Type | Description | Example |
| :--- | :--- | :--- |
| `int` / `i64` | 64-bit signed integer (two's complement wrapping) | `42`, `-10`, `0xFF`, `0b1010` |
| `decimal` | Exact fixed-point base-10 number (scale $10^4$, currency & finance) | `12.34m`, `0.05m`, `100m` |
| `float` / `double` | 64-bit IEEE 754 floating-point | `3.14159`, `-0.5` |
| `f32` | 32-bit IEEE 754 single-precision float | `1.5` |
| `u8`, `i8`, `u16`, `i16`, `u32`, `i32` | Explicit fixed-width integer types | `255`, `-128`, `65535` |
| `bool` | Boolean flag | `true`, `false` |
| `char` | 32-bit Unicode scalar value | `'A'`, `'ç'`, `'\n'` |
| `string` | UTF-8 encoded byte stream | `"Hello, World!"` |
| `array[T]` | Dynamic array | `[1, 2, 3, 4]` |
| `struct` | Named structure with typed fields | `struct User { name: string, age: int }` |

### 5 Canonical Rules for Primitive Types
1. **Floating-Point Representation**: `float` and `double` are 64-bit IEEE 754 double precision (`f64`). `f32` is single-precision.
2. **Text & Unicode**: `char` is a 32-bit Unicode code point (`u32`). `string` is a UTF-8 encoded byte sequence; lengths and offsets operate on raw UTF-8 bytes.
3. **Null Field Guarantees**: Uninitialized struct references default to `null` (`0`). Calling a method or accessing a field on a null reference triggers a deterministic runtime panic (`Null pointer dereference`).
4. **Integer Overflow**: Integer operations wrap according to standard 64-bit two's complement arithmetic (`wrapping_add`, `wrapping_sub`, `wrapping_mul`). Division by zero triggers a deterministic runtime panic (`kaz_panic_divzero`).
5. **Exact Decimal Arithmetic**: The `decimal` type is scaled by $10,000$ (4 decimal places), avoiding binary floating-point roundoff (e.g. `0.1m + 0.2m == 0.3m`). Arithmetic is hardware-accelerated with 128-bit intermediate integer math.

---

## 4. Variables, Constants, and Scoping

Variables are declared using `let`, `mut`, or `const`:

```rust
// Immutable variable (cannot be reassigned)
let max_connections = 100;

// Mutable variable
mut current_count = 0;
current_count = current_count + 1;

// Compile-time constant
const APP_VERSION = "1.5.0";
```

Variables have lexical block scope delimited by `{ ... }`.

---

## 5. Operators & Expressions

### Arithmetic, Relational, and Logical
- **Arithmetic**: `+`, `-`, `*`, `/`, `%`
- **Comparison**: `==`, `!=`, `<`, `<=`, `>`, `>=`
- **Logical**: `&&` (AND), `||` (OR), `!` (NOT)
- **Bitwise**: `&`, `|`, `^`, `<<`, `>>`

### Ternary Operator
```rust
let status = (age >= 18) ? "Adult" : "Minor";
```

---

## 6. Control Flow

### Conditionals
```rust
if score >= 90 {
    println("Grade: A");
} else if score >= 80 {
    println("Grade: B");
} else {
    println("Grade: C");
}
```

### Modern `for..in` Loop
Iterating over arrays directly:
```rust
let items = ["Apple", "Banana", "Cherry"];
for item in items {
    println("Item:", item);
}
```

### Traditional `while` Loop
```rust
mut counter = 0;
while counter < 5 {
    println("Count:", counter);
    counter = counter + 1;
}
```

---

## 7. Functions & Closures

Functions are declared with the `fn` keyword:

```rust
fn add(a: int, b: int) -> int {
    return a + b;
}

fn greet(name: string) {
    println("Hello,", name);
}
```

Recursion is fully supported and optimized by the Stack VM and AOT compiler.

---

## 8. Structs & OOP Features

Structs define custom data types with named fields:

```rust
struct Point {
    x: int,
    y: int
}

let p = Point { x: 10, y: 20 };
println("Point coordinates:", p.x, p.y);
```

Fields can be accessed and mutated:
```rust
mut user = User { name: "Alice", active: true };
user.active = false;
```

---

## 9. Error Handling (`try` / `catch`)

Kaz provides robust structured exception handling with deterministic stack unwinding:

```rust
try {
    let content = fs.read_to_string("missing_file.txt");
    println(content);
} catch err {
    println("Encountered error:", err);
}
```

---

## 10. Built-in Native Testing (`test`)

Test blocks are first-class language constructs:

```rust
test "arithmetic operations" {
    let result = 2 + 2;
    assert(result == 4, "2 + 2 must equal 4");
}
```

Run test suites directly using the CLI:
```bash
kaz test
```

---

## 11. Module System & Imports

Organize large applications across multiple files:

```rust
// Importing another Kaz file
import "helpers.kaz";

// Using imported functions
let formatted = format_currency(150.0);
```

Circular imports are automatically detected and prevented at compile time.
