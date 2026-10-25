# Relatório de Aceitação Técnica: Integridade Criptográfica dos Tensores e Formato KZM

**Data de Emissão:** 25 de Outubro de 2026  
**Ambiente de Teste:** Linux x86_64 · Intel Core i7 / Xeon (AVX2, FMA) · Kaz Native Runtime 1.5.0  
**Status do Laudo:** **APROVADO (Fase 2a: Formato Soberano, Sharding e Integridade Criptográfica)**

---

## 1. Escopo e Classificação da Fase 2

Conforme a separação arquitetural do ecossistema:
- **Fase 2a (Formato, Sharding e Integridade Criptográfica):** Conversão de Safetensors para o formato soberano `.kzm` (incluindo modelos multi-shard), preservação do conjunto de nomes, alinhamento de memória em 64 bytes, integridade de dtypes/shapes e correspondência byte a byte (SHA-256).
- **Fase 2b (Loader Nativo em Kaz Puro & Tokenizador BPE):** Implementação do parser binário e do tokenizador BPE em Kaz nativo com validação determinística de 100 frases contra referências.

---

## 2. Resultados dos Testes de Aceitação da Fase 2a

### A. Teste de Sharding & Escala: AllenAI OLMo-2 1B (5.6 GB)
O modelo `OLMo-2-0425-1B` é distribuído em múltiplos shards e possui arquitetura completa CausalLM (16 camadas, 2048 hidden dimension, 16 attention heads, 100.352 vocab size).

- **Script:** [`examples/ai/roundtrip_sharded_test.kaz`](file:///home/armando/Projetos/kaz/examples/ai/roundtrip_sharded_test.kaz)
- **Arquivos de Origem:**
  - Shard 1: `model-00001-of-00002.safetensors` (4.7 GB, 173 tensores)
  - Shard 2: `model-00002-of-00002.safetensors` (913 MB, 6 tensores)
- **Destino:** `olmo-2-1b.kzm` (5.664 MB, 179 tensores unificados)

| Métrica Avaliada | Safetensors Origem | KZM Destino | Validação |
| :--- | :---: | :---: | :---: |
| **Contagem de Tensores** | 179 tensores (173 + 6) | 179 tensores | **100% Exato** |
| **Conjunto de Nomes** | 179 nomes únicos | 179 nomes únicos | **100% Exato** |
| **Integridade de Shape / Tamanho** | 179 verificados | 179 verificados | **100% Exato** |
| **Integridade de Bytes (SHA-256)** | 179 hashes SHA-256 | 179 hashes SHA-256 | **179/179 Matches (100%)** |
| **Tempo de Hash (11.8 GB lidos)** | — | — | **126 segundos (~93.6 MB/s)** |

#### Amostra dos Shards do OLMo-2 1B:
- `[1/179] ✓ (Shard 1) model.embed_tokens.weight` (822.083.584 bytes) -> SHA-256: `d8ee0366d704dba055d3b74ff68dacd842e1cc83e96d3a9ddfd38012c81fbbad`
- `[2/179] ✓ (Shard 1) model.layers.0.mlp.down_proj.weight` (67.108.864 bytes) -> SHA-256: `26cfb5442177313d70474dcc6abf84f4842d3ac69b132299698826a59cf42f17`
- `[174/179] ✓ (Shard 2) lm_head.weight` (822.083.584 bytes) -> SHA-256: `e326fcabc18b60fd57ee1201ce158224a92a4d66fa8f4c62cbea7c10a4e63793`
- `[179/179] ✓ (Shard 2) model.norm.weight` (8.192 bytes) -> SHA-256: `a86cc4e7f8f6a7faa08936a432e54ebdf50e0564ccb8da6eada5fe044674f86b`

---

### B. Teste Sintético Rápido para CI/CD (Borda, Alinhamento e Multi-Dtype)
Para evitar tempos de CI proibitivos decorrentes do download e processamento de arquivos de 127 MB ou 5.6 GB, foi criado um teste unitário determinístico em memória:
- **Arquivo:** [`tests/synthetic_safetensors_test.rs`](file:///home/armando/Projetos/kaz/tests/synthetic_safetensors_test.rs)
- **Cenários Cobertos:**
  1. **Tensores Alinhados (F32):** 64 bytes (4x4 floats).
  2. **Tensores com Tamanho Desalinhado (BF16):** 34 bytes (17 elementos de 2 bytes — propositalmente não-múltiplo de 64 para testar o padding zero-byte de alinhamento no `.kzm`).
  3. **Tensores Não-Float (I64):** 16 bytes (2 elementos inteiros de 64 bits).
  4. **Tensores Vazios:** 0 bytes (elementos vazios com offset nulo).
  5. **Conversão Multi-Shard:** 2 shards sintéticos unificados com preservação de índices.
- **Resultado:** Executa e valida em **< 5 milissegundos** no pipeline contínuo do Cargo (`cargo test`).
- **Verificação de Alinhamento:** $100\%$ dos tensores com `file_offset % 64 == 0`.

---

## 3. Análise da Vazão de Hashing Criptográfico

A CPU de testes possui suporte a `AVX2`, `FMA` e `AES`, mas não dispõe do conjunto de instruções dedicado `SHA-NI` (*SHA New Instructions* presente em CPUs mais recentes). Portanto:
- O cálculo do hash SHA-256 é processado via **software puro** através da crate padrão `sha2` (com paralelismo escalar e SIMD genérico).
- A velocidade obtida de ~94 MB/s a ~120 MB/s reflete a taxa combinada de varredura sequencial em memória virtual e processamento SHA-256 em software sem aceleração dedicada de hardware.
- A terminologia foi corrigida: não se trata de SHA acelerado por hardware dedicado, mas sim processado por software na CPU host.

---

## 4. Conclusão Técnica da Fase 2a

1. O unificador de shards `kzm_convert_sharded_safetensors` foi validado em um modelo de grande porte com 5.6 GB, preservando 179 tensores sem sobreposição ou deslocamento de bytes.
2. O padding de 64 bytes foi validado em tensores arbitrários não múltiplos de 64 sem corrupção de dados adjacentes.
3. A suíte de testes de CI passou a rodar em milissegundos via modelos sintéticos, mantendo os testes com pesos reais como opcionais (`#[ignore]`).
4. **Fase 2a aprovada.** O foco agora avança para a Fase 2b (Loader em Kaz puro e Tokenizador determinístico).
