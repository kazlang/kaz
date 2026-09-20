# Guia Oficial da Linguagem Kaz 🦅

Bem-vindo ao manual completo de referência da linguagem de programação **Kaz**.  
Kaz é uma linguagem moderna, tipada, expressiva e de alto desempenho projetada para aliar a clareza e elegância sintática à robustez da compilação para **Máquina Virtual de Bytecode (Stack VM)** implementada em Rust.

---

## 📑 Sumário

1. [Visão Geral & Filosofia](#1-visão-geral--filosofia)
2. [Sintaxe Básica & Comentários](#2-sintaxe-básica--comentários)
3. [Sistema de Tipos & Literais](#3-sistema-de-tipos--literais)
4. [Variáveis, Constantes e Escopo](#4-variáveis-constantes-e-escopo)
5. [Operadores e Expressões](#5-operadores-e-expressões)
   - [Aritméticos, Relacionais e Lógicos](#operadores-gerais)
   - [Operador Ternário (? :)](#operador-ternário)
6. [Controle de Fluxo](#6-controle-de-fluxo)
   - [Condicionais (if, else if, else)](#condicionais)
   - [Loop Moderno for..in e .indices](#loop-for-in)
   - [Loop Tradicional for](#loop-for-clássico)
   - [Loop while](#loop-while)
   - [Controle de Interrupção (break e continue)](#break-e-continue)
7. [Funções e Ponto de Entrada](#7-funções-e-ponto-de-entrada)
   - [Declaração e Parâmetros Tipados](#declaração-de-funções)
   - [Execução Automática de Main()](#ponto-de-entrada-main)
   - [Recursão Profunda](#recursão)
8. [Estruturas de Dados Personalizadas (struct)](#8-estruturas-de-dados-personalizadas-struct)
9. [Arrays, Tipagem e Métodos Nativos](#9-arrays-tipagem-e-métodos-nativos)
10. [Sistema Modular Multi-Arquivos (import)](#10-sistema-modular-multi-arquivos-import)
11. [Banco de Dados Relacional SQLite Embutido (db.*)](#11-banco-de-dados-relacional-sqlite-embutido-db)
12. [Serialização e Parsing JSON (json.*)](#12-serialização-e-parsing-json-json)
13. [Rede e Comunicação HTTP (net.*)](#13-rede-e-comunicação-http-net)
14. [Motor de Execução (Stack Bytecode VM)](#14-motor-de-execução-stack-bytecode-vm)
15. [Diagnóstico de Erros](#15-diagnóstico-de-erros)

---

## 1. Visão Geral & Filosofia

Kaz foi concebida sob os seguintes pilares de engenharia:
- **Segurança Estrita de Tipos**: Prevenção de comportamentos indefinidos através de tipagem verificada em tempo de compilação e execução.
- **Desempenho Nativo sem Complicações**: Compilação instantânea para Bytecode contíguo de baixo nível executado por uma Máquina Virtual baseada em Pilha (Stack VM) em Rust.
- **Baterias Inclusas de Verdade**: Suporte nativo a banco de dados relacional SQLite, requisições HTTP REST, TCP sockets e serialização JSON embutidos diretamente no binário (zero dependências externas).
- **Arquitetura Modular para Softwares Reais**: Suporte total a projetos divididos em pastas com importações relativas e proteção anti-ciclo.

---

## 2. Sintaxe Básica & Comentários

Todo comando em Kaz termina com ponto e vírgula (`;`). Blocos de código são delimitados por chaves (`{ }`).

```kaz
// Comentário de linha única

/*
   Comentário em bloco
   de múltiplas linhas
*/

runoff("Olá, mundo!"); // 'runoff' é a função nativa padrão de saída
```

---

## 3. Sistema de Tipos & Literais

Kaz possui um sistema de tipos rico e estrito:

| Tipo | Descrição | Exemplo de Sintaxe | Valor Padrão |
|---|---|---|---|
| `int` | Inteiro de 64 bits com sinal | `int total = 100;` | `0` |
| `float` / `double` | Ponto flutuante IEEE 754 de 64 bits | `float pi = 3.14159;` | `0.0` |
| `string` | Texto UTF-8 com suporte a sequências de escape | `string msg = "Kaz 🦅\nLinha 2";` | `""` |
| `char` | Caractere Unicode individual | `char letra = 'K';` | `'\0'` |
| `bool` / `bol` | Booleano lógico | `bool ativo = true;` | `false` |
| `array[T]` | Array dinâmico tipado homogêneo | `array[string] itens = ["A", "B"];` | `[]` |
| `array[any]` | Array dinâmico heterogêneo | `array[any] misto = [1, "dois", true];` | `[]` |
| `struct` | Estrutura de dados personalizada | `Usuario u = Usuario { ... };` | Campos nulos |
| `void` | Ausência explícita de valor | `function log(): void { ... }` | `void` |

---

## 4. Variáveis, Constantes e Escopo

### Declaração e Inicialização
```kaz
int idade = 25;
string nome = "Armando";
float salario = 7500.50;
bool ativo = true;
```

### Constantes Imutáveis (`const`)
A palavra-chave `const` protege o identificador contra reatribuições durante toda a execução:
```kaz
const float PI = 3.14159;
string const SERVIDOR = "https://api.kaz.org";

// PI = 3.14; // ERRO: Não é possível atribuir novo valor à constante 'PI'!
```

### Escopo Léxico
Variáveis declaradas dentro de blocos (`{ }`) vivem apenas dentro daquele bloco, liberando memória automaticamente:
```kaz
int global = 10;

if (global > 0) {
    int local = 50;
    runoff(global + local); // 60
}

// runoff(local); // ERRO: Variável 'local' não encontrada neste escopo!
```

---

## 5. Operadores e Expressões

### Operadores Gerais
- **Aritméticos**: `+`, `-`, `*`, `/`, `%`
- **Atribuição Composta**: `+=`, `-=`, `*=`, `/=`, `%=`
- **Incremento / Decremento**: `x++`, `x--`
- **Comparação**: `==`, `!=`, `<`, `<=`, `>`, `>=`
- **Lógicos**: `&&` (E com curto-circuito), `||` (OU com curto-circuito), `!` (NÃO)
- **Concatenação de Strings**: Operador `+` (ex: `"Porta: " + 8080`)

### Operador Ternário (`? :`)
Permite atribuições e retornos condicionais compactos e legíveis:
```kaz
int idade = 20;
string status = (idade >= 18) ? "Maior de idade" : "Menor de idade";

// Suporta aninhamento elegante:
int pontos = 85;
string grau = (pontos >= 90) ? "A" : (pontos >= 80) ? "B" : "C";
```

---

## 6. Controle de Fluxo

### Condicionais
```kaz
int temperatura = 28;

if (temperatura > 30) {
    runoff("Clima quente.");
} else if (temperatura >= 20) {
    runoff("Clima agradável.");
} else {
    runoff("Clima frio.");
}
```

### Loop `for..in`
Iteração moderna sobre arrays com tipagem automática:

#### 1. Iterando sobre Valores:
```kaz
array[string] linguagens = ["Kaz", "Rust", "C"];

for (lang in linguagens) {
    runoff("Linguagem: " + lang);
}
```

#### 2. Iterando sobre Índices (`.indices`):
```kaz
for (i in linguagens.indices) {
    runoff("Posição " + i + ": " + linguagens[i]);
}
```

### Loop `for` Clássico
```kaz
int soma = 0;
for (int i = 1; i <= 100; i++) {
    soma += i;
}
runoff("Soma: " + soma);
```

### Loop `while`, `break` e `continue`
```kaz
int tentativas = 0;
while (true) {
    tentativas++;
    if (tentativas % 2 != 0) {
        continue; // Pula ímpares
    }
    if (tentativas >= 10) {
        break; // Interrompe o loop
    }
    runoff("Número par processado: " + tentativas);
}
```

---

## 7. Funções e Ponto de Entrada

### Declaração de Funções
```kaz
function calcular_desconto(float preco, float taxa): float {
    return preco * (1.0 - taxa);
}

function exibir_alerta(string mensagem): void {
    runoff("[ALERTA] " + mensagem);
}
```

### Ponto de Entrada `Main()`
Quando você define uma função `Main()` ou `main()`, o compilador Kaz a elege como ponto de entrada oficial e a executa automaticamente após carregar todos os módulos:
```kaz
function Main() {
    runoff("Aplicação iniciada com sucesso!");
}
```

### Recursão
Kaz suporta recursão profunda com otimização de chamadas na máquina virtual:
```kaz
function fibonacci(int n): int {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}
```

---

## 8. Estruturas de Dados Personalizadas (`struct`)

Permite modelar entidades ricas com campos tipados:

```kaz
struct Servidor {
    string ip;
    int porta;
    bool ativo;
}

// Instanciação:
Servidor srv = Servidor {
    ip: "127.0.0.1",
    porta: 8080,
    ativo: true
};

// Leitura e mutação de campos:
runoff("Conectando a " + srv.ip + ":" + srv.porta);
srv.porta = 9000;
srv.ativo = false;
```

---

## 9. Arrays, Tipagem e Métodos Nativos

Arrays em Kaz possuem métodos de alto nível embutidos:

```kaz
array[string] logs = [];

// Inserir elementos:
logs.push("Log 1: Boot inicializado");
logs.push("Log 2: Conexão efetuada");

// Tamanho da coleção:
int total = logs.len;

// Concatenação em string:
string relatorio = logs.join(" | ");

// Busca de elemento:
bool tem = logs.contains("Log 1: Boot inicializado");

// Remoção do último elemento:
logs.pop();
```

---

## 10. Sistema Modular Multi-Arquivos (`import`)

Kaz foi projetada para organizar códigos complexos em módulos e pastas:

### Estrutura de Diretórios Recomendada:
```text
meu_projeto/
├── main.kaz              # Ponto de entrada
├── models/
│   └── produto.kaz       # Definição de structs
└── db/
    └── conexao.kaz       # Gerenciamento de banco
```

### Exemplo de Uso:

`models/produto.kaz`:
```kaz
struct Produto {
    int id;
    string nome;
    float preco;
}

function criar_produto(int id, string nome, float preco): Produto {
    return Produto { id: id, nome: nome, preco: preco };
}
```

`main.kaz`:
```kaz
import "models/produto.kaz";

function Main() {
    Produto p = criar_produto(1, "Monitor 4K", 1850.00);
    runoff("Produto: " + p.nome + " por R$ " + p.preco);
}
```

> **Dica**: Você pode rodar a pasta inteira direto no terminal com `kaz meu_projeto` ou `kaz .`!

---

## 11. Banco de Dados Relacional SQLite Embutido (`db.*`)

Kaz possui um motor **SQLite compilado nativamente dentro do executável**. Nenhuma instalação externa ou driver é necessário.

```kaz
function Main() {
    // 1. Abrir ou criar banco (ou ":memory:" para RAM)
    int conn = db.open("loja.db");

    // 2. Executar comandos DDL/DML (CREATE, INSERT, UPDATE, DELETE)
    db.execute(conn, "CREATE TABLE IF NOT EXISTS clientes (id INTEGER PRIMARY KEY, nome TEXT, saldo REAL);");
    db.execute(conn, "INSERT INTO clientes (nome, saldo) VALUES ('Armando', 1500.0);");

    // 3. Consultas SQL (SELECT)
    array[any] linhas = db.query(conn, "SELECT id, nome, saldo FROM clientes;");
    for (linha in linhas) {
        runoff("ID: " + linha.id + " | Nome: " + linha.nome + " | Saldo: R$ " + linha.saldo);
    }

    // 4. Fechar conexão
    db.close(conn);
}
```

---

## 12. Serialização e Parsing JSON (`json.*`)

Manipulação nativa de objetos e dados estruturados:

```kaz
struct Config {
    string host;
    int porta;
}

Config cfg = Config { host: "localhost", porta: 3000 };

// Serializar para string JSON (com indentação se o 2º parâmetro for true):
string json_str = json.stringify(cfg, true);
runoff(json_str);

// Fazer o parse de JSON de volta para objetos Kaz:
any obj = json.parse("{\"status\":\"ok\",\"codigo\":200}");
runoff("Resposta da API: " + obj.status + " (" + obj.codigo + ")");
```

---

## 13. Rede e Comunicação HTTP (`net.*`)

Kaz possui clientes de rede nativos para integração REST e monitoramento:

```kaz
// 1. Medir latência TCP em milissegundos:
int ping_ms = net.ping("1.1.1.1", 53, 1000);
runoff("Latência DNS Cloudflare: " + ping_ms + " ms");

// 2. Fazer requisições HTTP GET:
string resposta = net.http_get("http://api.exemplo.com/usuarios");
runoff(resposta);

// 3. Fazer requisições HTTP POST:
string resposta_post = net.http_post("http://api.exemplo.com/login", "{\"user\":\"admin\"}", "application/json");
```

---

## 14. Motor de Execução (Stack Bytecode VM)

Por padrão, todo código Kaz é compilado diretamente para **Bytecode** e despachado na **Stack VM**, eliminando o custo de navegação em nós de árvores sintáticas.

```bash
# Execução padrão (Bytecode VM de alta performance):
kaz programa.kaz
kaz run programa.kaz

# Executar a pasta inteira de um projeto:
kaz meu_projeto/

# Modo de compatibilidade com o interpretador clássico AST:
kaz ast programa.kaz

# Verificar sintaxe sem rodar:
kaz check programa.kaz
```

---

## 15. Diagnóstico de Erros

Kaz gera mensagens claras, coloridas e com indicação visual da linha e coluna exatas de qualquer falha:

```text
Erro de sintaxe
arquivo: main.kaz
linha: 5
coluna: 18

Instrução inválida ou incompleta
   5 | int resultado = ;
     |                 ^
```

---

## 16. Testes Unitários Nativos Integrados 🧪

Kaz permite escrever suítes de testes unitários diretamente nos arquivos de código-fonte usando a palavra-chave `test` e a função `assert()`:

```kaz
function somar(int a, int b): int {
    return a + b;
}

function eh_par(int n): bool {
    return (n % 2) == 0;
}

// --------------------------------------------------
// Blocos de teste (ignorados na execução normal 'kaz run')
// --------------------------------------------------
test "validar operacao de soma" {
    assert(somar(10, 20) == 30, "10 + 20 deve ser igual a 30");
    assert(somar(-5, 5) == 0, "Soma de opostos deve zerar");
}

test "validar paridade de inteiros" {
    assert(eh_par(4) == true, "4 deve ser par");
    assert(eh_par(7) == false, "7 deve ser impar");
}
```

### Como Executar os Testes:
```bash
# Executa todos os testes do diretório:
kaz test

# Executa testes de um arquivo específico:
kaz test meu_arquivo.kaz
```

**Resultado no terminal:**
```text
running 2 test(s) in meu_arquivo.kaz:
  test "validar operacao de soma"          ... ok (0.42ms)
  test "validar paridade de inteiros"      ... ok (0.35ms)

test result: OK. 2 passed; 0 failed; finished in 1.15ms
```

