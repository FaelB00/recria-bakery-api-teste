# Teste técnico — Backend

Olá! Este teste existe para conversarmos sobre código de verdade, não sobre quebra-cabeças.
O problema abaixo é uma versão reduzida de coisas que a gente resolve toda semana: uma API
multi-loja, com dinheiro e estoque envolvidos, onde errar tem consequência.

**Leia este README inteiro antes de começar.** Ele foi escrito como um roteiro: o Bloco A é
guiado passo a passo, e cada passo tem um critério de aceite para você saber que terminou.

> Este roteiro diz **o que** entregar e **como verificar** que ficou pronto.
> Ele não diz **como** implementar — as decisões de implementação são suas,
> e é exatamente isso que estamos avaliando.

---

## 1. Regras do jogo

| | |
|---|---|
| **Prazo** | 3 dias corridos a partir do recebimento deste kit |
| **Esforço esperado** | 4 a 6 horas. Se estourar muito, pare e escreva no `DECISIONS.md` onde parou e por quê — isso conta a favor, não contra |
| **Stack obrigatória** | Python 3.11+, FastAPI, SQLAlchemy 2.0 **async** (com `asyncpg`), Pydantic v2, PostgreSQL, Docker |
| **Entrega** | Repositório Git (link público ou `.zip` com a pasta `.git` dentro) |
| **Uso de IA** | Liberado. Usamos IA aqui todos os dias. Mas a entrevista é sobre **o seu** código: você vai precisar explicar e defender cada decisão. Código que você não sabe justificar conta contra |

**O que NÃO avaliamos** — não gaste tempo com isso:

- Front-end de qualquer tipo
- Autenticação de verdade (login, JWT, hash de senha). A identidade da loja vem de um header simples, descrito no Passo 3
- Deploy, CI, cloud
- Cobertura de testes alta. Queremos poucos testes bons, não muitos testes rasos

---

## 2. O domínio

Uma rede de padarias com várias lojas. Cada loja compra insumos (farinha, manteiga, ovos) de
fornecedores, recebe as mercadorias, e consome esses insumos na produção do dia a dia.

Três coisas que valem entender antes de codar:

**Loja é o limite de tudo.** Cada loja tem um código de 8 dígitos (`store_code`). Fornecedor,
insumo, pedido e movimento de estoque pertencem a exatamente uma loja. Uma loja jamais pode ver
ou alterar dado de outra.

**Embalagem não é unidade.** A padaria compra em embalagem (uma caixa, um saco) mas controla
estoque em unidade base (kg, litro, unidade). Cada insumo tem um `units_per_package` que diz
quantas unidades base vêm em uma embalagem. Uma caixa de farinha com `units_per_package = 3`
entrega 3 kg de estoque.

**Estoque tem duas representações.** `ingredients.computed_stock` é o saldo atual — rápido de
ler. `stock_movements` é o livro-razão: toda entrada e toda saída vira uma linha lá. O saldo é
uma conveniência; o razão é a verdade.

A operação das padarias acontece em **America/Sao_Paulo**.

---

## 3. O banco que você recebe

Você **não** modela o banco: ele já vem pronto. O que você constrói é a API inteira por cima dele.

```bash
cp .env.example .env
docker compose up -d
docker compose logs postgres
```

No meio do log, procure a linha `seed ok`. Ela tem que dizer exatamente isto:

```
seed ok | lojas=2 fornecedores=12 insumos=30 pedidos=4 movimentos=10410 menor_saldo=1614.500
```

Conexão: `postgresql://bakery:bakery@localhost:5434/bakery`, schema `bakery`.

### As 5 tabelas

| Tabela | O que guarda |
|---|---|
| `suppliers` | Fornecedores da loja |
| `ingredients` | Insumos, com `units_per_package`, `computed_stock` e `average_cost` |
| `purchase_orders` | Pedidos de compra (cabeçalho), com `status` |
| `purchase_order_items` | Itens do pedido |
| `stock_movements` | Livro-razão: `CONSUMPTION`, `WASTE`, `ORDER_RECEIPT`, `ADJUSTMENT` |

Abra o `sql/01_schema.sql` e leia com atenção — ele está comentado. Repare em duas coisas:

1. A chave primária é **composta**: `(id, store_code)`. E as chaves estrangeiras carregam o
   `store_code` junto. Entenda o que isso significa antes de escrever o primeiro model.
2. **Não existe índice além dos que vêm de `PRIMARY KEY` e `UNIQUE`.** Isso é de propósito. Se
   você precisar de mais algum, crie o arquivo `sql/03_indexes.sql`.

**As duas lojas do seed são `10000001` e `10000002`.** Não edite `01_schema.sql` nem
`02_seed.sql` — avaliamos contra exatamente esses dados.

---

## 4. BLOCO A — obrigatório

Sete passos. Faça na ordem; cada um constrói em cima do anterior.

### Passo 0 — Ambiente

Suba o banco (seção 3) e confirme que consegue consultar as tabelas.

> **Aceite:** `docker compose up -d` sobe sem erro e a linha `seed ok` aparece no log.

---

### Passo 1 — Esqueleto e camadas

Crie o projeto com esta estrutura. Os nomes das pastas são obrigatórios — é assim que nosso
projeto real é organizado, e queremos ver você trabalhando nesse formato.

```
app/
├── main.py                 # cria o app FastAPI e registra as rotas
├── controllers/            # rotas HTTP (routers do FastAPI)
├── services/               # regra de negócio
├── repositories/           # acesso a banco
├── models/                 # models SQLAlchemy (mapeamento das tabelas)
├── dtos/                   # schemas Pydantic de entrada e saída
└── infra/
    ├── config.py           # leitura de variáveis de ambiente
    ├── database.py         # engine e sessão async
    ├── dependencies.py     # montagem das dependências (Depends)
    └── response.py         # envelope de resposta e catálogo de erros
tests/
```

O contrato entre as camadas é rígido. **Isto é o coração do teste:**

| Camada | Pode / deve | **Não pode** |
|---|---|---|
| **Controller** | Ler path, query, header e body; chamar **exatamente um** método de service; devolver a resposta usando os helpers do `response.py` | Ter `try`/`except`. Montar o envelope na mão. Importar SQLAlchemy. Conter regra de negócio |
| **Service** | Validar regra de negócio; orquestrar um ou mais repositories; decidir qual erro de negócio devolver | Importar FastAPI (`Request`, `HTTPException`, `Depends`). Escrever SQL ou usar a sessão do SQLAlchemy diretamente |
| **Repository** | Todo e qualquer acesso ao banco | Conter regra de negócio. Receber ou devolver DTO Pydantic (trabalhe com models e tipos simples) |
| **DTO** | Formato de entrada e de saída, validação de formato | Ser a mesma classe do model SQLAlchemy |
| **Model** | Mapeamento das tabelas | Acessar o banco |

Uma dependência só enxerga a camada imediatamente abaixo: controller → service → repository → model.
As dependências são montadas por funções no `infra/dependencies.py` e injetadas com `Depends`.

Crie também um `GET /health` que responda `{"status": "ok"}`.

> **Aceite:** `GET /health` devolve 200. A estrutura de pastas existe e cada arquivo está na
> camada certa.

---

### Passo 2 — Envelope de resposta e erros

**Toda** resposta da API, com sucesso ou com erro, tem o mesmo formato de dois campos:

```jsonc
// 200 — recurso
{ "data": { "id": "…", "name": "Moinho Aurora" }, "message": "OK" }

// 200 — listagem paginada
{ "data": { "items": [ … ], "meta": { "page": 1, "page_size": 20, "total": 137 } },
  "message": "OK" }

// 201 — criação
{ "data": { … }, "message": "Created" }

// 204 — remoção: sem corpo nenhum

// 404, 409, 422 — erro
{ "data": null, "message": "Supplier 'a1b2' não encontrado" }
```

Catálogo fechado de erros de negócio. Use exatamente estes status:

| Situação | HTTP |
|---|---|
| Recurso não existe, ou existe mas não é desta loja | `404` |
| Violação de unicidade (ex.: telefone repetido na mesma loja) | `409` |
| Regra de negócio violada | `422` |
| Corpo da requisição malformado ou com campo desconhecido | `422` |

Duas regras sobre como esses erros trafegam pelo código:

1. **Erro de negócio é valor de retorno do service, não exceção.** O service devolve ou o
   resultado, ou um objeto de erro. O controller recebe e traduz para HTTP.
2. **Por consequência: o controller não tem `try`/`except`.** Nenhum. Se você sentir vontade de
   escrever um, é sinal de que a responsabilidade está na camada errada.

Exceção continua existindo para falha de **infraestrutura** (banco fora do ar, bug não previsto).
Isso é tratado uma única vez, num handler global registrado no `main.py`, que devolve `500` no
mesmo envelope — e não em cada rota.

Requisições com campo desconhecido no corpo devem ser **rejeitadas com 422**, não ignoradas.

> **Aceite:** um endpoint de sucesso devolve `{"data": …, "message": "OK"}`; um erro devolve
> `{"data": null, "message": "…"}` com o status certo; nenhum controller tem `try`/`except`;
> mandar `{"nome_errado": 1}` num POST resulta em 422.

---

### Passo 3 — Identidade da loja

Toda rota (menos `/health`) exige o header **`X-Store-Code`**, com 8 dígitos numéricos.
É ele que diz de qual loja é a requisição.

- Header ausente → `422`
- Header fora do formato (`abc`, `123`, `123456789`) → `422`

> **Aceite:** `curl localhost:8000/v1/suppliers` sem o header devolve 422;
> com `-H "X-Store-Code: 10000001"` devolve a lista da loja 1;
> com `-H "X-Store-Code: 10000002"` devolve a lista da loja 2, e elas são diferentes.

---

### Passo 4 — CRUD de fornecedores

Prefixo `/v1`.

| Método | Rota | Corpo | Sucesso | Erros |
|---|---|---|---|---|
| `GET` | `/v1/suppliers` | — | `200` + listagem paginada | — |
| `GET` | `/v1/suppliers/{id}` | — | `200` | `404` |
| `POST` | `/v1/suppliers` | `{ "name", "contact_phone" }` | `201` | `409`, `422` |
| `PATCH` | `/v1/suppliers/{id}` | qualquer subconjunto de `{ "name", "contact_phone", "is_active" }` | `200` | `404`, `409`, `422` |
| `DELETE` | `/v1/suppliers/{id}` | — | `204` | `404` |

Detalhes que fazem parte do aceite:

- **Query params do `GET` da lista:** `page` (padrão `1`), `page_size` (padrão `20`, máximo `100`),
  `search` e `is_active` (padrão `true`).
- **`search`** casa com parte do nome, sem diferenciar maiúsculas de minúsculas.
- **`DELETE` é lógico:** marca `is_active = false`. A linha continua no banco. Um fornecedor
  inativo some da listagem padrão e reaparece com `?is_active=false`.
- **`contact_phone` é gravado só com dígitos.** O front manda mascarado
  (`"+55 (11) 90000-0001"`); a API grava `"5511900000001"`. Duas máscaras diferentes do mesmo
  número são o mesmo telefone e a segunda tem que dar `409`.
- **A resposta nunca devolve `store_code`.** É informação interna.

Exemplo completo:

```bash
curl -X POST localhost:8000/v1/suppliers \
  -H "X-Store-Code: 10000001" \
  -H "Content-Type: application/json" \
  -d '{"name": "Moinho Novo", "contact_phone": "+55 (11) 90000-0099"}'
```

```json
{
  "data": {
    "id": "3f1c…",
    "name": "Moinho Novo",
    "contact_phone": "5511900000099",
    "is_active": true,
    "created_at": "2026-08-14T12:00:00Z",
    "updated_at": "2026-08-14T12:00:00Z"
  },
  "message": "Created"
}
```

> **Aceite:** cada linha da tabela acima funciona; criar dois fornecedores com o mesmo telefone
> na mesma loja dá `409`; buscar pelo `id` de um fornecedor da outra loja dá `404`.

---

### Passo 5 — Insumos

Três endpoints, o suficiente para exercitar a relação com fornecedores.

| Método | Rota | Corpo | Sucesso | Erros |
|---|---|---|---|---|
| `GET` | `/v1/ingredients` | — | `200` + listagem paginada | — |
| `GET` | `/v1/ingredients/{id}` | — | `200` | `404` |
| `POST` | `/v1/ingredients` | `{ "name", "measure_unit", "units_per_package", "default_supplier_id"? }` | `201` | `404`, `409`, `422` |

- **Query params do `GET` da lista:** `page`, `page_size`, `search` (parte do nome) e
  `supplier_id` (filtra pelo fornecedor padrão).
- **`measure_unit`** só aceita `KG`, `UN` ou `L`.
- **`units_per_package`** tem que ser maior que zero.
- **Regra de negócio:** se `default_supplier_id` vier preenchido, ele tem que ser um fornecedor
  **desta loja**. Um id que não existe e um id que existe mas é de outra loja devem produzir a
  **mesma** resposta: `404`.
- **A resposta traz `computed_stock` e `average_cost`.**

> **Aceite:** criar um insumo apontando para
> `default_supplier_id = "22222222-0000-4000-8000-000000000001"` (fornecedor da loja 2) com o
> header da loja `10000001` devolve `404` — e não `500`.

---

### Passo 6 — Testes

Três testes. **Não queremos mais que isso** — queremos estes três bem feitos.

1. Um erro de negócio devolvido pelo service vira `404` na resposta HTTP.
2. Um `POST` com campo desconhecido no corpo é rejeitado com `422`.
3. A loja `10000002` não consegue ler nem alterar um recurso da loja `10000001`.

Regra da casa, e ela vale nota: **cada teste declara, no docstring, qual classe de bug ele pega
que os outros dois não pegam.** Se você não conseguir escrever essa frase, o teste provavelmente
é redundante.

Os testes têm que rodar sem banco de dados — troque as dependências por dublês.

> **Aceite:** `pytest` roda verde a partir de um clone limpo, seguindo só o seu README,
> **sem o Postgres no ar**.

---

### Passo 7 — Documentação

- **`README.md`** — como subir e como testar. Alguém que nunca viu seu projeto tem que conseguir
  em 5 minutos.
- **`DECISIONS.md`** — responda as 4 perguntas do arquivo `DECISIONS.md` que veio neste kit.
  Máximo 1 página no total. **Este arquivo pesa na avaliação tanto quanto um item do Bloco B.**
- **Commits** — queremos ver o histórico. Vários commits pequenos com mensagem descritiva
  (usamos [Conventional Commits](https://www.conventionalcommits.org/pt-br/)), não um commit
  único chamado "projeto".

> **Aceite:** clonamos, seguimos seu README, e funciona.

---

## 5. BLOCO B — opcional

Aqui o roteiro acaba de propósito. Cada item abaixo diz **o objetivo** e **como verificamos** —
o caminho é problema seu.

> **Prefira 2 opcionais bem feitos e testados a 5 pela metade.**
> Bloco A malfeito com muitos opcionais pontua **menos** que Bloco A impecável e nenhum opcional.
> O que você não fizer, escreva no `DECISIONS.md` como faria.

| # | Objetivo | Como verificamos | Peso |
|---|---|---|---|
| **D1** | **Recebimento de mercadoria.** `POST /v1/orders/{id}/actions/receive` recebe as quantidades que chegaram de fato, item a item. Para cada item: registra o quanto veio, compara com o que foi pedido e classifica como `OK` ou `DIVERGENT`; credita o estoque do insumo; registra uma linha `ORDER_RECEIPT` no livro-razão. Ao final o pedido vira `RECEIVED` | Recebemos o pedido `cccccccc-0000-4000-8000-000000000001` da loja `10000001` e conferimos `computed_stock`, `stock_movements` e `purchase_order_items` no banco. Também mandamos um item inválido no meio da lista e conferimos que **nada** foi gravado | ★★★ |
| **D2** | **Recebimento à prova de repetição e de corrida.** O mesmo recebimento enviado duas vezes, e dois recebimentos disparados ao mesmo tempo, não podem produzir um saldo errado | Chamamos o endpoint duas vezes com o mesmo corpo e conferimos o saldo. Depois disparamos duas chamadas concorrentes. Queremos ver também o teste que **você** escreveu para isso | ★★★ |
| **D3** | **Relatório analítico.** `GET /v1/reports/ingredients?from=&to=` devolve, por insumo no período: total recebido, total consumido, total desperdiçado, último custo unitário praticado e saldo atual. Paginado. **Escrito em SQL** (`text()` com parâmetros vinculados), não montado com o ORM. Entregue junto o `EXPLAIN (ANALYZE, BUFFERS)` antes e depois dos seus índices, e um `sql/03_indexes.sql` com **um comentário justificando cada índice** | Rodamos `?from=2026-03-01&to=2026-03-05` e conferimos os números contra uma consulta nossa. Lemos os planos de execução e a sua justificativa | ★★★ |
| **D4** | **Ciclo de vida do pedido.** `POST /v1/orders` cria em `DRAFT` com itens (cada item é pedido **ou** em embalagens **ou** em unidades, nunca nos dois). `POST /v1/orders/{id}/actions/place` leva de `DRAFT` para `PLACED`. Transição inválida é erro de negócio com `409` — não pode chegar como erro do banco | Tentamos dar `place` num pedido já `PLACED` e esperamos `409` com o envelope normal. Mandamos um item com as duas quantidades preenchidas e esperamos `422` | ★★ |
| **D5** | **Testes contra Postgres de verdade.** Um script ou fixture que sobe um banco descartável, aplica o schema do zero e roda os testes que precisam de banco — separados dos testes do Passo 6 | Rodamos seu comando numa máquina limpa | ★★ |
| **D6** | **Exatidão de valores e de períodos.** Os totais em dinheiro batem centavo a centavo, e um relatório de `2026-03-01` a `2026-03-05` devolve exatamente os movimentos que a padaria registrou nesses cinco dias — nem um a mais, nem um a menos | Conferimos contra os valores reais do seed, incluindo os movimentos das bordas do intervalo | ★★ |
| **D7** | **Empacotamento.** `Dockerfile` da API (multi-stage, rodando como usuário não-root), atalho para os comandos do dia a dia (`make` ou equivalente), `ruff` e `mypy` configurados e passando limpo | Buildamos a imagem e rodamos seus comandos | ★ |
| **D8** | **Contrato de API.** OpenAPI com exemplos de corpo, respostas de erro documentadas por rota, e rota versionada | Abrimos o `/docs` e comparamos com o comportamento real | ★ |

---

## 6. O que entregar

1. Repositório Git com histórico de commits
2. `README.md` — como subir, como rodar os testes
3. `DECISIONS.md` — as 4 perguntas respondidas
4. Se fez D3: o `EXPLAIN` e o `sql/03_indexes.sql`

---

## 7. Como avaliamos

Transparência total sobre o peso:

| | Pontos |
|---|---|
| **Bloco A — obrigatório** | **60** |
| ↳ Disciplina de camadas e injeção de dependências | 18 |
| ↳ Contrato da API e tratamento de erro | 12 |
| ↳ Isolamento entre lojas | 12 |
| ↳ `DECISIONS.md` | 10 |
| ↳ Os três testes | 8 |
| **Bloco B — opcional** (teto de 40) | **40** |

Uma observação honesta: **o Bloco B só entra na conta se o Bloco A estiver sólido.** O roteiro do
Bloco A é detalhado justamente para que ele não seja o problema — dá para fazer bem feito em
umas 3 horas.

E o que a gente mais olha não está em nenhuma tabela: se o código está no lugar certo, se os
nomes dizem o que as coisas são, e se você consegue explicar por que fez de um jeito e não de
outro. É por isso que o `DECISIONS.md` vale tanto.

Boa sorte. Qualquer dúvida sobre o enunciado, pergunte — perguntar não desconta nada.
