# 🎬 Roteiro de Gravação: Microserviço Kaz ERP Gateway
> **Tema:** Construção de um Microserviço Local de Alta Performance para Consulta de CEP & CNPJ com Cache SQLite em Kaz Lang, consumido por ERP em C# / Delphi.

---

## 📌 Sugestões de Títulos para o Vídeo
1. **"Criei uma Linguagem de Programação e fiz um Microserviço para meu ERP!"** *(Alta atração)*
2. **"Adeus lentidão e limites de API de CEP/CNPJ: Microserviço em Kaz com SQLite em <1ms"**
3. **"Construindo um Servidor HTTP com Cache SQLite em 170 linhas de Kaz Lang"**

---

## ⏱️ Timeline & Roteiro Detalhado ("A Cola")

```
[00:00 - 00:35] 🪝 O Gancho (O Problema Real de ERPs)
[00:35 - 01:20] ⚡ Demonstração Ao Vivo (A Solução Pronta rodando em <1ms)
[01:20 - 03:00] 🧠 O Código em Kaz Lang (170 linhas: SQLite + TCP + HTTP)
[03:00 - 03:50] 🔌 Integração no ERP (C# .NET / Delphi)
[03:50 - 04:40] 🛡️ A Prova de Fogo (200 Testes Unitários, Stress e AOT Nativo)
[04:40 - 05:00] 🚀 Conclusão & Link do GitHub
```

---

### [00:00 - 00:35] 🪝 O Gancho (O Problema Real)
* **O que mostrar na tela:** Sua tela com o ERP aberto (tela de cadastro de clientes/empresas com os campos de CEP e CNPJ) ou um slide rápido com o diagrama do problema.
* **O que falar:**
  > *"Se você desenvolve ERP ou sistemas de gestão comercial — seja em C#, Delphi, Java ou Web — você com certeza já passou por isso: o usuário digita o CNPJ ou CEP no cadastro da empresa, clica em 'Buscar', e a tela congela por 2 a 3 segundos esperando uma API pública responder. Pior ainda: quando o provedor te bloqueia por excesso de requisições ou sai do ar, o seu cliente não consegue nem salvar o cadastro.*
  > 
  > *Pra resolver isso definitivamente na nova versão do meu ERP, eu decidi construir um microserviço local que atua como gateway de alta performance: se o dado já foi consultado uma vez por qualquer estação, ele responde do SQLite local em **menos de 1 milissegundo**. E o mais louco: eu escrevi ele do zero em **Kaz**, a linguagem de programação que estou desenvolvendo."*

---

### [00:35 - 01:20] ⚡ Demonstração Ao Vivo
* **O que mostrar na tela:** Terminal rodando `kaz examples/erp_gateway.kaz` e o navegador ao lado com as abas de teste.
* **Passos no vídeo:**
  1. No terminal:
     ```bash
     kaz examples/erp_gateway.kaz
     ```
     *(Mostra o banner e o log: `Servidor HTTP ativo em: http://127.0.0.1:5000`)*
  2. No navegador, acesse: `http://localhost:5000/cep/01001000` (Praça da Sé)
     - Mostre o terminal: `[🌐 CACHE MISS] Buscando CEP 01001000 na API remota...` e `[💾 SALVO NO SQLITE]`.
  3. Dê **F5 (Refresh)** imediatamente na mesma página:
     - Mostre o terminal: `[⚡ CACHE HIT SQLite] CEP 01001000 servido em sub-milissegundo!`.
     - Abra o DevTools (F12) na aba Network: tempo de resposta **0.7ms**!
  4. Repita com o CNPJ da Globo: `http://localhost:5000/cnpj/27865757000102`.
     - Primeira consulta: busca na ReceitaWS e salva.
     - Segunda consulta: cache instantâneo em 0.6ms.
  5. Acesse `http://localhost:5000/stats` mostrando o total de registros persistidos no SQLite.

---

### [01:20 - 03:00] 🧠 O Código em Kaz Lang (Line-by-Line)
* **O que mostrar na tela:** O arquivo `examples/erp_gateway.kaz` aberto no VS Code (com a extensão de sintaxe Kaz ativa).
* **Pontos-chave para explicar:**
  1. **Inicialização do SQLite (Linhas 60-64):**
     ```kaz
     int db = db_open("erp_cache.db");
     db_execute(db, "CREATE TABLE IF NOT EXISTS ceps (cep TEXT PRIMARY KEY, json TEXT, criado_em DATETIME DEFAULT CURRENT_TIMESTAMP);");
     db_execute(db, "CREATE TABLE IF NOT EXISTS cnpjs (cnpj TEXT PRIMARY KEY, json TEXT, criado_em DATETIME DEFAULT CURRENT_TIMESTAMP);");
     ```
     *Destaque:* Banco de dados relacional integrado direto na linguagem nativa, sem precisar de bibliotecas pesadas ou drivers ODBC.
  2. **Servidor de Rede Nativo (Linhas 67-84):**
     ```kaz
     int server = net_listen(5000);
     while (true) {
         int client = net_accept(server);
         string req = net_read(client);
         ...
     ```
     *Destaque:* Controle de sockets TCP com syntax limpa de C/Rust.
  3. **Lógica de Fallback Inteligente (Linhas 97-115):**
     * Primeiro roda um `db_query` no SQLite.
     * Se houver linha, responde instantaneamente com CORS liberado.
     * Se não houver, faz requisição remota com `net_http_get`, persiste no banco e entrega o JSON limpo.

---

### [03:00 - 03:50] 🔌 Integração no ERP (C# .NET & Delphi)
* **O que mostrar na tela:** O código de exemplo em C# mostrando como o ERP consome o microserviço.

#### Exemplo em C# (.NET 8 / WPF / Windows Forms):
```csharp
// No evento de clique do botão "Consultar CNPJ" do ERP:
public async Task BuscarEmpresaAsync(string cnpj)
{
    using var client = new HttpClient();
    try 
    {
        // Chama o gateway local do Kaz
        string json = await client.GetStringAsync($"http://localhost:5000/cnpj/{cnpj}");
        var empresa = JsonSerializer.Deserialize<EmpresaDto>(json);
        
        txtRazaoSocial.Text = empresa.Nome;
        txtFantasia.Text = empresa.Fantasia;
        txtLogradouro.Text = empresa.Logradouro;
        txtBairro.Text = empresa.Bairro;
        txtCidade.Text = empresa.Municipio;
        txtUf.Text = empresa.Uf;
    }
    catch (Exception ex)
    {
        MessageBox.Show($"Falha ao consultar CNPJ: {ex.Message}");
    }
}
```

* **O que falar:**
  > *"No seu ERP, são literalmente 4 linhas de código. O C# só precisa fazer um `GetStringAsync` pro `localhost:5000`. O ERP não precisa saber se o dado veio da internet ou do disco; ele sempre recebe o JSON padronizado com latência praticamente zero."*

---

### [03:50 - 04:40] 🛡️ A Prova de Fogo (Testes & Confiabilidade)
* **O que falar:**
  > *"Mas aí você pode se perguntar: 'Isso é só um brinquedo ou a linguagem é realmente sólida e estável? Quem garante que isso não vai quebrar?' Deixa eu te mostrar o nosso pipeline de verificação."*
* **O que rodar no terminal:**
  ```bash
  ./scripts/test_all.sh
  ```
* **O que destacar na tela enquanto roda (leva segundos):**
  1. **174 Testes Unitários de Compilador e VM (Rust)**: Validação de tipos, AST, dispatch e memória.
  2. **16 Testes Nativos Kaz (`test runner`)**: Escritos na própria linguagem testando enums, structs, condicionais e recursão.
  3. **Testes de Stress de Carga**: Alocação de 50.000 itens em array (39ms) e pilha profunda de 1.000 frames (800µs).
  4. **Compilação Nativa AOT (ELF64 / Máquina pura)**: Executáveis compilados direto para código de máquina rodando e validando fibonacci, loops e structs.
  *Destaque:* *"São 200 testes automatizados que garantem que nenhuma feature nova quebra as anteriores."*

---

### [04:40 - 05:00] 🚀 Conclusão & Chamada para Ação
* **O que falar:**
  > *"O Kaz está crescendo a passos largos. A linguagem já tem compilação JIT, compilação AOT nativa para binário puro, banco de dados SQLite, suporte a rede TCP e HTTP, e sintaxe moderna e tipada.*
  > 
  > *Todo o código desse microserviço e da linguagem está aberto no GitHub (link na descrição). Se você gostou, deixa aquela estrela no repositório, se inscreve no canal e comenta o que você gostaria de ver construído em Kaz no próximo vídeo! Valeu e até a próxima!"*

---

## 🛠️ Checklist Rápido Pré-Gravação
- [ ] Terminal com fonte legível (16px+ ou zoom aumentado).
- [ ] Banco `erp_cache.db` limpo antes de iniciar (`rm -f erp_cache.db`) para demonstrar o primeiro miss e depois o hit.
- [ ] Abas do navegador pré-abertas ou salvas nos favoritos.
- [ ] VS Code aberto em `examples/erp_gateway.kaz`.
- [ ] Microfone e áudio testados.
