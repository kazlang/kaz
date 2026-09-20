# Referência da Biblioteca Padrão (Stdlib) 📚

A Biblioteca Padrão de Kaz reúne módulos nativos compilados em Rust diretamente no binário `kaz.exe`.  
Isso significa **máxima velocidade de execução e zero necessidade de instalar bibliotecas de terceiros**.

---

## 📑 Módulos Disponíveis

1. [Entrada, Saída & Asserções (`io`)](#1-entrada-saída--asserções-io)
2. [Conversão de Tipos (`convert`)](#2-conversão-de-tipos-convert)
3. [Matemática (`math.*`)](#3-matemática-math)
4. [Manipulação de Strings (`str`)](#4-manipulação-de-strings-str)
5. [Arrays e Coleções (`arr`)](#5-arrays-e-coleções-arr)
6. [Sistema de Arquivos Moderno (`fs.*`)](#6-sistema-de-arquivos-moderno-fs)
7. [Criptografia e Hashes (`crypto.*`)](#7-criptografia-e-hashes-crypto-)
8. [Expressões Regulares (`regex.*`)](#8-expressões-regulares-regex-)
9. [Rede e HTTP (`net.*`)](#9-rede-e-http-net)
10. [Banco de Dados Relacional SQLite (`db.*`)](#10-banco-de-dados-relacional-sqlite-db)
11. [Serialização e Parsing JSON (`json.*`)](#11-serialização-e-parsing-json-json)
12. [Tempo e Sistema (`time`)](#12-tempo-e-sistema-time)

---

## 1. Entrada, Saída & Asserções (`io`)

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `runoff(...)` | `...valores: any` | `void` | Imprime um ou mais valores no terminal seguidos de quebra de linha. |
| `println(...)` | `...valores: any` | `void` | Sinônimo padrão de `runoff`. |
| `print(...)` | `...valores: any` | `void` | Imprime valores no terminal **sem** quebra de linha no final. |
| `input(mensagem?)` | `mensagem?: string` | `string` | Exibe mensagem opcional e aguarda o usuário digitar uma linha de texto. |
| `read_line()` | *(nenhum)* | `string` | Lê uma linha de texto do teclado. |
| `assert(cond, msg?)` | `cond: bool, msg?: string` | `bool` | Valida uma condição lógica. Falha com erro de asserção se for falsa. |

```kaz
runoff("Total:", 100, "itens processados.");
string nome = input("Digite seu nome: ");
runoff("Olá, " + nome);
assert(10 > 5, "10 deve ser maior que 5");
```


---

## 2. Conversão de Tipos (`convert`)

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `to_int(valor)` | `valor: any` | `int` | Converte string, float ou bool para número inteiro. |
| `to_float(valor)` | `valor: any` | `float` | Converte string, int ou bool para ponto flutuante. |
| `to_string(valor)` | `valor: any` | `string` | Converte qualquer valor ou struct para representação em texto. |
| `to_bool(valor)` | `valor: any` | `bool` | Converte número ou texto para booleano. |
| `type_of(valor)` | `valor: any` | `string` | Retorna o nome textual do tipo do dado (ex: `"int"`, `"string"`, `"Usuario"`). |

```kaz
int num = to_int("1234");      // 1234
float preco = to_float("49.9");// 49.9
string t = type_of([1, 2, 3]); // "array"
```

---

## 3. Matemática (`math.*`)

Acesso via namespace `math.<funcao>()` ou chamada global direta:

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `math.sqrt(x)` | `x: float` | `float` | Raiz quadrada de `x`. |
| `math.pow(base, exp)` | `base, exp: float` | `float` | Potenciação: base elevada ao expoente. |
| `math.abs(x)` | `x: int` ou `float` | `int` ou `float` | Valor absoluto (módulo) do número. |
| `math.random()` | *(nenhum)* | `float` | Gera número aleatório entre `0.0` e `1.0`. |
| `math.sin(rad)` | `rad: float` | `float` | Seno em radianos. |
| `math.cos(rad)` | `rad: float` | `float` | Cosseno em radianos. |
| `math.tan(rad)` | `rad: float` | `float` | Tangente em radianos. |
| `math.floor(x)` | `x: float` | `float` | Arredonda para baixo. |
| `math.ceil(x)` | `x: float` | `float` | Arredonda para cima. |
| `math.round(x)` | `x: float` | `float` | Arredonda para o inteiro mais próximo. |
| `math.min(a, b)` | `a, b: int` ou `float` | Mesmo tipo | Retorna o menor entre `a` e `b`. |
| `math.max(a, b)` | `a, b: int` ou `float` | Mesmo tipo | Retorna o maior entre `a` e `b`. |

```kaz
float hipotenusa = math.sqrt(math.pow(3.0, 2.0) + math.pow(4.0, 2.0)); // 5.0
int sorteio = to_int(math.random() * 100.0);
```

---

## 4. Manipulação de Strings (`str`)

Podem ser chamadas como funções (`str_upper(s)`) ou como métodos na própria string (`s.upper()`):

| Método / Função | Retorno | Descrição |
|---|---|---|
| `s.len` / `str_len(s)` | `int` | Quantidade de caracteres na string. |
| `s.upper()` / `str_upper(s)` | `string` | Converte texto para letras maiúsculas. |
| `s.lower()` / `str_lower(s)` | `string` | Converte texto para letras minúsculas. |
| `s.trim()` / `str_trim(s)` | `string` | Remove espaços no início e fim. |
| `s.split(sep)` / `str_split(s, sep)` | `array[string]` | Divide o texto pelo delimitador `sep`. |
| `s.replace(de, para)` / `str_replace(...)` | `string` | Substitui substrings. |
| `s.contains(busca)` / `str_contains(...)` | `bool` | Retorna `true` se o texto contiver a busca. |
| `s.starts_with(pre)` / `str_starts_with(...)` | `bool` | Checa prefixo. |
| `s.ends_with(pos)` / `str_ends_with(...)` | `bool` | Checa sufixo. |
| `s.substring(ini, fim)` | `string` | Extrai fatia da string. |

```kaz
string texto = "   Kaz Language   ";
string limpo = texto.trim().upper(); // "KAZ LANGUAGE"
array[string] partes = "a,b,c".split(","); // ["a", "b", "c"]
```

---

## 5. Arrays e Coleções (`arr`)

| Método / Função | Retorno | Descrição |
|---|---|---|
| `arr.len` / `len(arr)` | `int` | Quantidade de elementos na coleção. |
| `arr.indices` | `array[int]` | Array contendo todos os índices numéricos válidos. |
| `arr.push(elem)` | `void` | Insere `elem` no final do array. |
| `arr.pop()` | `any` | Remove e retorna o último elemento. |
| `arr.join(separador)` | `string` | Concatena elementos intercalados por um separador. |
| `arr.contains(elem)` | `bool` | Checa se o elemento está presente no array. |
| `arr.reverse()` | `array` | Retorna o array com a ordem invertida. |

```kaz
array[string] lista = ["maçã", "banana"];
lista.push("laranja");
runoff(lista.join(" -> ")); // "maçã -> banana -> laranja"
```

---

## 6. Sistema de Arquivos Moderno (`fs.*`)

Kaz oferece operações síncronas completas para arquivos e diretórios:

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `fs.mkdir(caminho)` | `caminho: string` | `bool` | Cria diretórios recursivamente (`mkdir -p`). |
| `fs.read_dir(caminho)` | `caminho: string` | `array[string]` | Lista nomes de arquivos e pastas contidos no diretório. |
| `fs.read(caminho)` / `file_read` | `caminho: string` | `string` | Lê todo o conteúdo de um arquivo como string. |
| `fs.write(caminho, texto)` / `file_write` | `caminho, texto: string` | `bool` | Grava conteúdo no arquivo (sobrescrevendo se existir). |
| `fs.append(caminho, texto)` / `file_append` | `caminho, texto: string` | `bool` | Anexa conteúdo ao final do arquivo. |
| `fs.exists(caminho)` / `file_exists` | `caminho: string` | `bool` | Verifica se o arquivo ou pasta existe no disco. |
| `fs.remove(caminho)` / `file_delete` | `caminho: string` | `bool` | Exclui arquivo ou diretório recursivamente. |
| `fs.copy(origem, destino)` | `origem, destino: string` | `bool` | Copia arquivo da origem para o destino. |
| `fs.size(caminho)` | `caminho: string` | `int` | Retorna o tamanho do arquivo em bytes. |

```kaz
fs.mkdir("backups/2026");
fs.write("backups/2026/relatorio.txt", "Dados consolidados\n");
fs.append("backups/2026/relatorio.txt", "Nova entrada registrada\n");

int bytes = fs.size("backups/2026/relatorio.txt");
runoff("Tamanho do arquivo:", bytes, "bytes");

array[string] arquivos = fs.read_dir("backups/2026");
runoff("Conteúdo da pasta:", arquivos);
```

---

## 7. Criptografia e Hashes (`crypto.*`) 🔐

Módulo embutido para integridade de dados e senhas:

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `crypto.sha256(texto)` | `texto: string` | `string` | Gera o hash criptográfico SHA-256 em formato hexadecimal (64 caracteres). |
| `crypto.md5(texto)` | `texto: string` | `string` | Gera o hash MD5 em formato hexadecimal. |
| `crypto.base64_encode(texto)` | `texto: string` | `string` | Converte texto para codificação Base64. |
| `crypto.base64_decode(texto_b64)` | `texto_b64: string` | `string` | Decodifica string Base64 para texto UTF-8. |

```kaz
string senha = "admin_segredo_2026";
string hash = crypto.sha256(senha);
runoff("SHA-256:", hash);

string token_b64 = crypto.base64_encode("usuario:token123");
string original = crypto.base64_decode(token_b64);
```

---

## 8. Expressões Regulares (`regex.*`) 🎯

Módulo de validação e extração de padrões com alto desempenho:

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `regex.is_match(padrao, texto)` | `padrao, texto: string` | `bool` | Verifica se o padrão regex ocorre no texto. |
| `regex.find(padrao, texto)` | `padrao, texto: string` | `string` | Extrai a primeira correspondência (ou `""` se não encontrar). |
| `regex.replace(padrao, texto, substituto)` | `padrao, texto, substituto: string` | `string` | Substitui todas as ocorrências do padrão pelo substituto. |

```kaz
bool email_valido = regex.is_match("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "contato@kaz.org");
assert(email_valido == true);

string ano = regex.find("[0-9]{4}", "Lancamento em 2026 com sucesso");
runoff("Ano:", ano); // "2026"

string texto_limpo = regex.replace("[0-9]", "Cartao: 1234-5678", "*");
runoff(texto_limpo); // "Cartao: ****-****"
```

---

## 9. Rede e HTTP (`net.*`)

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `net.ping(host, porta, timeout_ms?)` | `host: string, porta: int, timeout_ms?: int` | `int` | Mede latência TCP em ms. Retorna `-1` em timeout/erro. |
| `net.http_get(url)` | `url: string` | `string` | Realiza requisição HTTP/1.1 GET e retorna corpo da resposta. |
| `net.http_post(url, body, content_type?)` | `url, body: string, content_type?: string` | `string` | Envia requisição HTTP/1.1 POST com payload. |
| `net.tcp_send(host, porta, msg)` | `host: string, porta: int, msg: string` | `string` | Envia mensagem por socket TCP bruto e retorna resposta. |

```kaz
int ping = net.ping("1.1.1.1", 53, 1000);
runoff("DNS Cloudflare Ping: " + ping + "ms");

string json_resposta = net.http_get("http://api.exemplo.com/dados");
```

---

## 10. Banco de Dados Relacional SQLite (`db.*`)

Motor relacional SQLite embutido diretamente no executável Kaz (zero dependências externas):

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `db.open(caminho)` | `caminho: string` | `int` | Abre ou cria arquivo SQLite (use `":memory:"` para banco em RAM). Retorna o ID da conexão. |
| `db.execute(conn, sql, params?)` | `conn: int, sql: string, params?: array` | `int` | Executa comandos SQL (`CREATE`, `INSERT`, `UPDATE`, `DELETE`). Retorna número de linhas afetadas. |
| `db.query(conn, sql, params?)` | `conn: int, sql: string, params?: array` | `array[any]` | Executa consultas `SELECT`. Retorna array onde cada linha é acessada por campo: `linha.nome`. |
| `db.close(conn)` | `conn: int` | `void` | Fecha a conexão com o banco e garante sincronização no disco. |

```kaz
int db_conn = db.open("banco.db");

db.execute(db_conn, "CREATE TABLE IF NOT EXISTS usuarios (id INTEGER PRIMARY KEY, nome TEXT);");
db.execute(db_conn, "INSERT INTO usuarios (nome) VALUES ('Armando');");

array[any] usuarios = db.query(db_conn, "SELECT id, nome FROM usuarios;");
for (u in usuarios) {
    runoff("ID: " + u.id + " | Nome: " + u.nome);
}

db.close(db_conn);
```

---

## 11. Serialização e Parsing JSON (`json.*`)

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `json.parse(texto_json)` | `texto_json: string` | `any` | Faz o parse de string JSON para objetos, structs, números e arrays de Kaz. |
| `json.stringify(valor, formatado?)` | `valor: any, formatado?: bool` | `string` | Converte structs, arrays ou valores para texto JSON (com indentação bonita se `true`). |

```kaz
struct Pedido { int id; float total; }
Pedido p = Pedido { id: 101, total: 250.0 };

string json_str = json.stringify(p, true);
runoff(json_str);

any payload = json.parse("{\"status\":\"sucesso\",\"codigo\":200}");
runoff("Status: " + payload.status);
```

---

## 12. Tempo e Sistema (`time`)

| Função | Parâmetros | Retorno | Descrição |
|---|---|---|---|
| `time_now_ms()` | *(nenhum)* | `int` | Timestamp UNIX atual em milissegundos. |
| `time_now_secs()` / `time_now()` | *(nenhum)* | `float` | Timestamp UNIX atual em segundos com precisão fracionária. |
| `sleep_ms(ms)` / `sleep(ms)` | `ms: int` | `void` | Pausa a execução pelo número especificado de milissegundos. |

```kaz
int inicio = time_now_ms();
sleep_ms(50);
int decorrido = time_now_ms() - inicio;
runoff("Operação levou " + decorrido + " ms");
```

