# Standard Library Reference (Stdlib) 📚

The Kaz Standard Library provides built-in native modules compiled directly into the binary with zero external dependencies.

---

## 📑 Available Modules

1. [Input, Output & Assertions (`io`)](#1-input-output--assertions-io)
2. [Type Conversions (`convert`)](#2-type-conversions-convert)
3. [Mathematics (`math.*`)](#3-mathematics-math)
4. [String Manipulation (`str`)](#4-string-manipulation-str)
5. [Arrays and Collections (`arr`)](#5-arrays-and-collections-arr)
6. [Modern Filesystem (`fs.*`)](#6-modern-filesystem-fs)
7. [Cryptography & Hashes (`crypto.*`)](#7-cryptography--hashes-crypto)
8. [Regular Expressions (`regex.*`)](#8-regular-expressions-regex)
9. [Networking & HTTP (`net.*`)](#9-networking--http-net)
10. [Embedded SQLite Database (`db.*`)](#10-embedded-sqlite-database-db)
11. [JSON Serialization & Parsing (`json.*`)](#11-json-serialization--parsing-json)

---

## 1. Input, Output & Assertions (`io`)

### `println(...args)`
Prints formatted arguments to standard output followed by a newline:
```rust
println("Value:", 42, true);
```

### `print(...args)`
Prints formatted arguments to standard output without appending a newline:
```rust
print("Processing: ");
```

### `input(prompt: string) -> string`
Displays a prompt and reads a line from standard input:
```rust
let name = input("Enter your name: ");
```

### `args() -> [string]`
Returns the command-line arguments passed to the script:
```rust
let params = args();
```

### `assert(condition: bool, message: string)`
Terminates execution with an assertion failure if `condition` is false:
```rust
assert(x > 0, "x must be positive");
```

---

## 2. Type Conversions (`convert`)

- `to_string(val: any) -> string`: Converts any value to its string representation.
- `to_int(val: any) -> int`: Parses strings, floats, or booleans to an integer.
- `to_float(val: any) -> float`: Parses strings or integers to a 64-bit float.
- `to_bool(val: any) -> bool`: Converts truthy/falsy values to a boolean.

---

## 3. Mathematics (`math.*`)

- `math.sqrt(n: float) -> float`: Returns the square root.
- `math.pow(base: float, exp: float) -> float`: Calculates exponentiation.
- `math.sin(rad: float) -> float`: Trigonometric sine.
- `math.cos(rad: float) -> float`: Trigonometric cosine.
- `math.tan(rad: float) -> float`: Trigonometric tangent.
- `math.abs(n: float) -> float`: Returns the absolute value.
- `math.floor(n: float) -> float`: Rounds down to the nearest integer.
- `math.ceil(n: float) -> float`: Rounds up to the nearest integer.
- `math.round(n: float) -> float`: Rounds to the nearest integer.
- `math.min(a: float, b: float) -> float`: Returns the smaller value.
- `math.max(a: float, b: float) -> float`: Returns the larger value.
- `math.PI`: The mathematical constant $\pi$ (`3.141592653589793`).
- `math.E`: Euler's constant $e$ (`2.718281828459045`).

---

## 4. String Manipulation (`str`)

- `len(s: string) -> int`: Returns the string length in bytes.
- `str.trim(s: string) -> string`: Strips leading and trailing whitespace.
- `str.to_upper(s: string) -> string`: Converts characters to uppercase.
- `str.to_lower(s: string) -> string`: Converts characters to lowercase.
- `str.split(s: string, delimiter: string) -> [string]`: Splits a string by delimiter.
- `str.join(arr: [string], separator: string) -> string`: Joins array elements into a string.
- `str.replace(s: string, target: string, replacement: string) -> string`: Replaces occurrences of a substring.
- `str.starts_with(s: string, prefix: string) -> bool`: Checks prefix.
- `str.ends_with(s: string, suffix: string) -> bool`: Checks suffix.
- `str.contains(s: string, sub: string) -> bool`: Checks if substring exists.
- `str.slice(s: string, start: int, end: int) -> string`: Extracts a substring.

---

## 5. Arrays and Collections (`arr`)

- `push(arr: [T], item: T)`: Appends an item to the end of an array.
- `pop(arr: [T]) -> T`: Removes and returns the last element.
- `len(arr: [T]) -> int`: Returns array element count.
- `clear(arr: [T])`: Clears all elements from the array.
- `reverse(arr: [T])`: Reverses array elements in place.

---

## 6. Modern Filesystem (`fs.*`)

- `fs.read_to_string(path: string) -> string`: Reads an entire file as a UTF-8 string.
- `fs.write_string(path: string, content: string)`: Writes or overwrites a file.
- `fs.append_string(path: string, content: string)`: Appends text to a file.
- `fs.exists(path: string) -> bool`: Checks whether a file or directory exists.
- `fs.is_file(path: string) -> bool`: Checks if path is a file.
- `fs.is_dir(path: string) -> bool`: Checks if path is a directory.
- `fs.remove_file(path: string)`: Deletes a file.
- `fs.create_dir(path: string)`: Creates a new directory.
- `fs.remove_dir_all(path: string)`: Recursively removes a directory.
- `fs.list_dir(path: string) -> [string]`: Lists entries in a directory.

---

## 7. Cryptography & Hashes (`crypto.*`)

- `crypto.sha256(data: string) -> string`: Computes SHA-256 hash (hex string).
- `crypto.md5(data: string) -> string`: Computes MD5 hash (hex string).
- `crypto.base64_encode(data: string) -> string`: Encodes string to Base64.
- `crypto.base64_decode(data: string) -> string`: Decodes Base64 string.

---

## 8. Regular Expressions (`regex.*`)

- `regex.is_match(pattern: string, text: string) -> bool`: Checks whether regex matches.
- `regex.find(pattern: string, text: string) -> string`: Returns first regex match.
- `regex.find_all(pattern: string, text: string) -> [string]`: Returns all matching occurrences.
- `regex.replace(pattern: string, text: string, rep: string) -> string`: Replaces regex matches.

---

## 9. Networking & HTTP (`net.*`)

- `net.http_get(url: string) -> string`: Performs an HTTP GET request and returns the body string.
- `net.http_post(url: string, body: string, content_type: string) -> string`: Sends an HTTP POST request.
- `net.tcp_connect(host: string, port: int) -> Connection`: Opens a raw TCP stream connection.
- `net.tcp_listen(host: string, port: int) -> Listener`: Binds a TCP listener socket.

---

## 10. Embedded SQLite Database (`db.*`)

Zero-setup embedded SQLite database engine:

```rust
let conn = db.open("data.db");
db.execute(conn, "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);");
db.execute(conn, "INSERT INTO users (name) VALUES ('Armando');");

let rows = db.query(conn, "SELECT id, name FROM users;");
for row in rows {
    println("User:", row.id, row.name);
}
db.close(conn);
```

---

## 11. JSON Serialization & Parsing (`json.*`)

- `json.parse(payload: string) -> any`: Parses a JSON string into Kaz maps, arrays, or primitive types.
- `json.stringify(value: any) -> string`: Serializes a Kaz structure into a compact JSON string.
- `json.pretty(value: any) -> string`: Serializes a Kaz structure into formatted, indented JSON.
