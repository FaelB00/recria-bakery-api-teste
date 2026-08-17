# Bakery API - Teste Rafael Bernardes

Este é o resultado de um teste técnico preparado pela recria.ia, que consiste na implementação de uma API REST para gestão de fornecedores(suppliers) e insumos(ingredients) de uma rede de padarias multi-loja, com isolamento total de dados entre lojas.

Stack: Python 3.11+, FastAPI, SQLAlchemy 2.0 (async, via `asyncpg`), Pydantic v2, PostgreSQL 18, Docker.

---

## Como subir o projeto

### Pré-requisitos

- Python 3.11 ou superior
- Docker e Docker Compose
- Git

### 1. Clonar e configurar variáveis de ambiente

```bash
git clone <url-deste-repositorio>
cd test_backend_developer
cp .env.example .env
```

### 2. Subir o banco de dados

```bash
docker compose up -d
docker compose logs postgres
```

No log, confirme que aparece a linha:

```
seed ok | lojas=2 fornecedores=12 insumos=30 pedidos=4 movimentos=10410 menor_saldo=1614.500
```

O Postgres fica exposto em `localhost:5434` (banco `bakery`, schema `bakery`), para não
conflitar com uma instalação local na porta padrão 5432.

### 3. Criar o ambiente virtual e instalar dependências

```bash
python -m venv .venv
```

Ativar o ambiente virtual:

```bash
# Windows (cmd)
.venv\Scripts\activate.bat

# Windows (PowerShell)
.venv\Scripts\activate

# Linux/Mac
source .venv/bin/activate
```

Instalar as dependências:

```bash
pip install -r requirements.txt
```

### 4. Rodar a API

```bash
uvicorn app.main:app --reload
```

A API sobe em `http://localhost:8000`. Documentação interativa (Swagger) disponível em
`http://localhost:8000/docs`.

Alternativamente, todos os comandos acima (exceto o clone) têm um atalho no `Makefile`:
`make up`, `make install`, `make run` — veja `make help` para a lista completa.

---

## Como testar manualmente

Todo endpoint de negócio exige o header `X-Store-Code` (8 dígitos numéricos), que identifica
a loja fazendo a requisição.

### Health check

```bash
curl http://localhost:8000/health
```

### Criar um fornecedor

```bash
curl -X POST localhost:8000/v1/suppliers \
  -H "X-Store-Code: 10000001" \
  -H "Content-Type: application/json" \
  -d '{"name": "Moinho Novo", "contact_phone": "+55 (11) 90000-0099"}'
```

### Listar fornecedores da loja

```bash
curl localhost:8000/v1/suppliers -H "X-Store-Code: 10000001"
```

### Criar um insumo (com fornecedor opcional)

```bash
curl -X POST localhost:8000/v1/ingredients \
  -H "X-Store-Code: 10000001" \
  -H "Content-Type: application/json" \
  -d '{"name": "Farinha de Trigo", "measure_unit": "KG", "units_per_package": 3}'
```

> No Windows, use aspas duplas escapadas com `\"` no lugar das aspas simples acima
> (ex.: `-d "{\"name\": \"Farinha de Trigo\", ...}"`), tanto no `cmd` quanto no PowerShell.

---

## Como rodar os testes automatizados

Os testes rodam sem necessidade de banco de dados — as dependências de banco são substituídas
por dublês (fakes/stubs) via `app.dependency_overrides` do FastAPI.

```bash
pytest -v
```

São 3 testes, cada um cobrindo uma camada diferente da aplicação (tradução de erro de negócio
para HTTP, validação de entrada, isolamento entre lojas). Veja o docstring de cada teste em
`tests/test_supplier_api.py` para o raciocínio completo por trás de cada um.

---

## Bloco B — opcionais implementados

Dos itens opcionais do Bloco B, foram implementados **D3** (relatório analítico) e **D7**
(empacotamento e qualidade de código). Os demais foram descartados — motivo detalhado em
[`DECISIONS.md`](./DECISIONS.md).

### D3 — Relatório analítico de insumos

`GET /v1/reports/ingredients?from=&to=` devolve, por insumo, o total recebido, consumido,
desperdiçado, o último custo unitário praticado no período e o saldo atual — paginado, e
escrito em SQL puro (`text()` com parâmetros vinculados) em `app/repositories/report_repository.py`,
não montado com o ORM.

```bash
curl "localhost:8000/v1/reports/ingredients?from=2020-01-01T00:00:00&to=2030-01-01T00:00:00" \
  -H "X-Store-Code: 10000001"
```

Um `from` posterior ao `to` é rejeitado com `422`.

#### Índices e EXPLAIN (ANALYZE, BUFFERS)

Os índices usados pela query estão em [`sql/03_indexes.sql`](./sql/03_indexes.sql), cada um
comentado com a justificativa. Resumo do ganho medido:

| Métrica | Antes | Depois |
|---|---|---|
| Buffers totais | 2779 | 204 (187 hit + 17 read) |
| Buffers só da subquery de `last_unit_cost` | 2621 (~94% do custo) | 49 |
| Execution Time | 26,6 ms | 5,79 ms |
| Plano da subquery | `Seq Scan` (10.104 linhas descartadas por execução, 17x) | `Index Scan` usando `idx_stock_movements_ingredient_store_moved_at` |

<details>
<summary>EXPLAIN completo — antes dos índices</summary>

```
Limit  (cost=399.49..5845.76 rows=15 width=162) (actual time=6.545..26.324 rows=17.00 loops=1)
  Buffers: shared hit=2779
  ->  Result  (cost=399.49..5845.76 rows=15 width=162) (actual time=6.544..26.317 rows=17.00 loops=1)
        Buffers: shared hit=2779
        ->  Sort  (cost=399.49..399.53 rows=15 width=144) (actual time=5.074..5.081 rows=17.00 loops=1)
              Sort Key: i.name
              Sort Method: quicksort  Memory: 27kB
              Buffers: shared hit=158
              ->  HashAggregate  (cost=398.86..399.20 rows=15 width=144) (actual time=4.995..5.007 rows=17.00 loops=1)
                    Group Key: i.name
                    Batches: 1  Memory Usage: 40kB
                    Buffers: shared hit=155
                    ->  Hash Right Join  (cost=1.56..353.32 rows=2602 width=65) (actual time=0.076..3.176 rows=5207.00 loops=1)
                          Hash Cond: (sm.ingredient_id = i.id)
                          Buffers: shared hit=155
                          ->  Seq Scan on stock_movements sm  (cost=0.00..336.18 rows=5204 width=42) (actual time=0.008..1.949 rows=5205.00 loops=1)
                                Filter: ((moved_at >= '2020-01-01 00:00:00+00') AND (moved_at <= '2030-01-01 00:00:00+00') AND (store_code = '10000001'))
                                Rows Removed by Filter: 5205
                                Buffers: shared hit=154
                          ->  Hash  (cost=1.38..1.38 rows=15 width=48) (actual time=0.041..0.041 rows=17.00 loops=1)
                                Buckets: 1024  Batches: 1  Memory Usage: 10kB
                                Buffers: shared hit=1
                                ->  Seq Scan on ingredients i  (cost=0.00..1.38 rows=15 width=48) (actual time=0.020..0.023 rows=17.00 loops=1)
                                      Filter: (store_code = '10000001')
                                      Rows Removed by Filter: 15
                                      Buffers: shared hit=1
        SubPlan 1
          ->  Limit  (cost=363.07..363.07 rows=1 width=14) (actual time=1.246..1.246 rows=0.88 loops=17)
                Buffers: shared hit=2621
                ->  Sort  (cost=363.07..363.50 rows=173 width=14) (actual time=1.234..1.234 rows=0.88 loops=17)
                      Sort Key: sm2.moved_at DESC
                      Sort Method: top-N heapsort  Memory: 25kB
                      Buffers: shared hit=2621
                      ->  Seq Scan on stock_movements sm2  (cost=0.00..362.20 rows=173 width=14) (actual time=0.149..1.172 rows=306.18 loops=17)
                            Filter: ((moved_at >= '2020-01-01 00:00:00+00') AND (moved_at <= '2030-01-01 00:00:00+00') AND (ingredient_id = i.id) AND (store_code = i.store_code))
                            Rows Removed by Filter: 10104
                            Buffers: shared hit=2618
Planning:
  Buffers: shared hit=244
Planning Time: 3.261 ms
Execution Time: 26.608 ms
```

</details>

<details>
<summary>EXPLAIN completo — depois dos índices</summary>

```
Limit  (cost=399.49..443.56 rows=15 width=162) (actual time=5.109..5.558 rows=17.00 loops=1)
  Buffers: shared hit=187 read=17
  ->  Result  (cost=399.49..443.56 rows=15 width=162) (actual time=5.108..5.553 rows=17.00 loops=1)
        Buffers: shared hit=187 read=17
        ->  Sort  (cost=399.49..399.53 rows=15 width=144) (actual time=4.962..4.968 rows=17.00 loops=1)
              Sort Key: i.name
              Sort Method: quicksort  Memory: 27kB
              Buffers: shared hit=155
              ->  HashAggregate  (cost=398.86..399.20 rows=15 width=144) (actual time=4.911..4.924 rows=17.00 loops=1)
                    Group Key: i.name
                    Batches: 1  Memory Usage: 40kB
                    Buffers: shared hit=155
                    ->  Hash Right Join  (cost=1.56..353.32 rows=2602 width=65) (actual time=0.135..3.050 rows=5207.00 loops=1)
                          Hash Cond: (sm.ingredient_id = i.id)
                          Buffers: shared hit=155
                          ->  Seq Scan on stock_movements sm  (cost=0.00..336.18 rows=5204 width=42) (actual time=0.044..1.824 rows=5205.00 loops=1)
                                Filter: ((moved_at >= '2020-01-01 00:00:00+00') AND (moved_at <= '2030-01-01 00:00:00+00') AND (store_code = '10000001'))
                                Rows Removed by Filter: 5205
                                Buffers: shared hit=154
                          ->  Hash  (cost=1.38..1.38 rows=15 width=48) (actual time=0.060..0.061 rows=17.00 loops=1)
                                Buckets: 1024  Batches: 1  Memory Usage: 10kB
                                Buffers: shared hit=1
                                ->  Seq Scan on ingredients i  (cost=0.00..1.38 rows=15 width=48) (actual time=0.019..0.024 rows=17.00 loops=1)
                                      Filter: (store_code = '10000001')
                                      Rows Removed by Filter: 15
                                      Buffers: shared hit=1
        SubPlan 1
          ->  Limit  (cost=0.29..2.92 rows=1 width=14) (actual time=0.033..0.033 rows=0.88 loops=17)
                Buffers: shared hit=32 read=17
                ->  Index Scan using idx_stock_movements_ingredient_store_moved_at on stock_movements sm2  (cost=0.29..456.30 rows=173 width=14) (actual time=0.032..0.032 rows=0.88 loops=17)
                      Index Cond: ((ingredient_id = i.id) AND (store_code = i.store_code) AND (moved_at >= '2020-01-01 00:00:00+00') AND (moved_at <= '2030-01-01 00:00:00+00'))
                      Index Searches: 17
                      Buffers: shared hit=32 read=17
Planning:
  Buffers: shared hit=42 read=2
Planning Time: 7.226 ms
Execution Time: 5.791 ms
```

</details>

Nota: o segundo índice (`idx_stock_movements_store_moved_at`, para o `JOIN` principal) não foi
usado pelo planner nesse cenário — a faixa filtrada cobre ~metade da tabela, e nesse caso o
`Seq Scan` é mais barato que o índice. Mantido para lojas/períodos mais seletivos, onde compensa.

### D7 — Empacotamento e qualidade de código

- **`ruff`** (linter) e **`mypy`** (checagem de tipos) configurados em `pyproject.toml`, rodando limpos.
- **`Makefile`** com atalhos para os comandos do dia a dia (`make help` lista todos).
- **`Dockerfile`** multi-stage (build enxuto, sem ferramentas de compilação na imagem final) rodando como usuário não-root (`appuser`).

```bash
make lint       # ruff check .
make typecheck  # mypy app
make check      # lint + typecheck + test, em sequência
```

Build e execução via Docker:

```bash
docker build -t bakery-api .

# a API precisa estar na mesma rede do Postgres do docker-compose:
docker network ls   # confirme o nome, ex.: test_backend_developer_default

docker run --rm -p 8000:8000 \
  --network test_backend_developer_default \
  -e DB_URL=postgresql+asyncpg://bakery:bakery@postgres:5432/bakery \
  bakery-api

# confirma que não roda como root:
docker exec <container_id> whoami   # esperado: appuser
```

---

## Estrutura do projeto

```
app/
├── controllers/    # Rotas HTTP. Sem lógica de negócio, sem acesso a banco.
├── services/        # Regra de negócio. Erros de negócio são retornados como valor
│                    # (BusinessError), nunca lançados como exceção.
├── repositories/    # Acesso ao banco via SQLAlchemy async. Sem regra de negócio.
├── models/          # Mapeamento das tabelas (SQLAlchemy).
├── dtos/             # Contratos de entrada/saída da API (Pydantic).
└── infra/            # Configuração, sessão de banco, envelope de resposta,
                       # injeção de dependências (Depends).
tests/                # Testes automatizados (sem banco real).
sql/                  # Schema, seed e índices do banco (03_indexes.sql é o único
                       # arquivo criado por nós; 01 e 02 vieram prontos no kit).
Dockerfile            # Build multi-stage, usuário não-root (D7).
Makefile              # Atalhos para os comandos do dia a dia (D7).
pyproject.toml        # Configuração do ruff e do mypy (D7).
```

Cada requisição segue sempre o mesmo caminho: **controller → service → repository → banco**,
nunca pulando camada. Erros de negócio esperados (não encontrado, duplicado) são valores de
retorno; falhas de infraestrutura inesperadas são capturadas por um handler global em
`app/main.py`, que garante que toda resposta — sucesso ou erro — segue o mesmo formato:

```json
{ "data": { ... }, "message": "OK" }
{ "data": null, "message": "Fornecedor 'x' não encontrado" }
```

---

## Decisões de design

As decisões e trade-offs relevantes estão documentados em [`DECISIONS.md`](./DECISIONS.md).