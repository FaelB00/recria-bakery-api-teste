-- =============================================================================
-- Teste técnico Backend — schema base
--
-- NÃO EDITE ESTE ARQUIVO. Ele é aplicado automaticamente pelo docker-compose
-- e a avaliação assume exatamente estas tabelas. Se precisar criar índices,
-- crie um arquivo novo `sql/03_indexes.sql`.
--
-- Domínio: gestão de insumos de uma rede de padarias com várias lojas.
-- Tenant : `store_code` — 8 dígitos numéricos. TODA tabela é escopada por loja.
--
-- Repare que a chave primária de quase toda tabela é COMPOSTA: (id, store_code).
-- Isso não é enfeite — é o que permite que as chaves estrangeiras carreguem o
-- `store_code` junto e o banco garanta que uma loja nunca referencie dado de
-- outra loja.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS bakery;


-- -----------------------------------------------------------------------------
-- suppliers — fornecedores
-- -----------------------------------------------------------------------------
CREATE TABLE bakery.suppliers (
    id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    store_code    CHAR(8)      NOT NULL,
    name          VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20)  NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_suppliers              PRIMARY KEY (id, store_code),
    CONSTRAINT uq_suppliers_phone        UNIQUE (store_code, contact_phone),
    CONSTRAINT ck_suppliers_store_code   CHECK (store_code ~ '^[0-9]{8}$'),
    CONSTRAINT ck_suppliers_name         CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_suppliers_phone_digits CHECK (contact_phone ~ '^[0-9]+$')
);

COMMENT ON TABLE  bakery.suppliers IS 'Fornecedores, escopados por loja.';
COMMENT ON COLUMN bakery.suppliers.contact_phone IS
    'Telefone somente dígitos. Único por loja — dois fornecedores da mesma loja não podem ter o mesmo telefone.';
COMMENT ON COLUMN bakery.suppliers.is_active IS
    'Flag de visibilidade. A remoção de fornecedor é lógica, não física.';


-- -----------------------------------------------------------------------------
-- ingredients — insumos
-- -----------------------------------------------------------------------------
CREATE TABLE bakery.ingredients (
    id                  UUID          NOT NULL DEFAULT gen_random_uuid(),
    store_code          CHAR(8)       NOT NULL,
    name                VARCHAR(255)  NOT NULL,
    measure_unit        VARCHAR(10)   NOT NULL,
    units_per_package   NUMERIC(12,3) NOT NULL,
    default_supplier_id UUID,
    computed_stock      NUMERIC(14,3) NOT NULL DEFAULT 0,
    average_cost        NUMERIC(14,4) NOT NULL DEFAULT 0,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_ingredients            PRIMARY KEY (id, store_code),
    CONSTRAINT uq_ingredients_name       UNIQUE (store_code, name),
    CONSTRAINT ck_ingredients_store_code CHECK (store_code ~ '^[0-9]{8}$'),
    CONSTRAINT ck_ingredients_name       CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_ingredients_upp        CHECK (units_per_package > 0),
    CONSTRAINT ck_ingredients_unit       CHECK (measure_unit IN ('KG', 'UN', 'L')),

    -- Chave estrangeira COMPOSTA: o fornecedor tem de ser da MESMA loja.
    CONSTRAINT fk_ingredients_supplier
        FOREIGN KEY (default_supplier_id, store_code)
        REFERENCES bakery.suppliers (id, store_code)
);

COMMENT ON COLUMN bakery.ingredients.units_per_package IS
    'Quantas unidades base cabem em uma embalagem de compra. Ex.: 3 = uma caixa contém 3 KG.';
COMMENT ON COLUMN bakery.ingredients.computed_stock IS
    'Saldo em UNIDADE BASE. É um valor denormalizado: a verdade é a soma de bakery.stock_movements.';
COMMENT ON COLUMN bakery.ingredients.average_cost IS
    'Custo médio por UNIDADE BASE (não por embalagem).';


-- -----------------------------------------------------------------------------
-- purchase_orders — pedidos de compra (cabeçalho)
-- -----------------------------------------------------------------------------
CREATE TABLE bakery.purchase_orders (
    id          UUID          NOT NULL DEFAULT gen_random_uuid(),
    store_code  CHAR(8)       NOT NULL,
    supplier_id UUID          NOT NULL,
    status      VARCHAR(20)   NOT NULL DEFAULT 'DRAFT',
    placed_at   TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    total_cost  NUMERIC(14,2) NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_purchase_orders            PRIMARY KEY (id, store_code),
    CONSTRAINT ck_purchase_orders_store_code CHECK (store_code ~ '^[0-9]{8}$'),
    CONSTRAINT ck_purchase_orders_status
        CHECK (status IN ('DRAFT', 'PLACED', 'RECEIVED', 'CANCELLED')),

    CONSTRAINT fk_purchase_orders_supplier
        FOREIGN KEY (supplier_id, store_code)
        REFERENCES bakery.suppliers (id, store_code)
);

COMMENT ON COLUMN bakery.purchase_orders.status IS
    'Ciclo de vida do pedido: DRAFT -> PLACED -> RECEIVED, ou -> CANCELLED. '
    'O CHECK aqui é a última rede de segurança do banco, não a regra de negócio.';


-- -----------------------------------------------------------------------------
-- purchase_order_items — itens do pedido
-- -----------------------------------------------------------------------------
CREATE TABLE bakery.purchase_order_items (
    id                  UUID          NOT NULL DEFAULT gen_random_uuid(),
    store_code          CHAR(8)       NOT NULL,
    order_id            UUID          NOT NULL,
    ingredient_id       UUID          NOT NULL,
    ordered_package_qty NUMERIC(12,3),
    ordered_unit_qty    NUMERIC(14,3),
    received_unit_qty   NUMERIC(14,3),
    package_cost        NUMERIC(14,4) NOT NULL,
    status              VARCHAR(20)   NOT NULL DEFAULT 'DRAFT',
    divergence_status   VARCHAR(20),
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_purchase_order_items PRIMARY KEY (id, store_code),
    CONSTRAINT ck_poi_store_code       CHECK (store_code ~ '^[0-9]{8}$'),
    CONSTRAINT ck_poi_status
        CHECK (status IN ('DRAFT', 'PLACED', 'RECEIVED', 'CANCELLED')),
    CONSTRAINT ck_poi_divergence
        CHECK (divergence_status IS NULL OR divergence_status IN ('OK', 'DIVERGENT')),

    -- Um item é pedido OU em embalagens OU em unidades — nunca nos dois, nunca em nenhum.
    CONSTRAINT ck_poi_qty_exactly_one CHECK (
        (ordered_package_qty IS NOT NULL AND ordered_unit_qty IS NULL)
        OR
        (ordered_package_qty IS NULL AND ordered_unit_qty IS NOT NULL)
    ),
    CONSTRAINT ck_poi_qty_positive CHECK (
        COALESCE(ordered_package_qty, 1) > 0 AND COALESCE(ordered_unit_qty, 1) > 0
    ),

    CONSTRAINT fk_poi_order
        FOREIGN KEY (order_id, store_code)
        REFERENCES bakery.purchase_orders (id, store_code) ON DELETE CASCADE,
    CONSTRAINT fk_poi_ingredient
        FOREIGN KEY (ingredient_id, store_code)
        REFERENCES bakery.ingredients (id, store_code)
);

COMMENT ON COLUMN bakery.purchase_order_items.package_cost IS
    'Custo de UMA EMBALAGEM (não de uma unidade base).';
COMMENT ON COLUMN bakery.purchase_order_items.received_unit_qty IS
    'Quantidade efetivamente recebida, sempre em UNIDADE BASE. NULL enquanto o item não foi recebido.';
COMMENT ON COLUMN bakery.purchase_order_items.divergence_status IS
    'NULL antes do recebimento. Depois: OK quando recebido == pedido, DIVERGENT caso contrário.';


-- -----------------------------------------------------------------------------
-- stock_movements — livro-razão de estoque
-- -----------------------------------------------------------------------------
CREATE TABLE bakery.stock_movements (
    id              BIGSERIAL     NOT NULL,
    store_code      CHAR(8)       NOT NULL,
    ingredient_id   UUID          NOT NULL,
    movement_type   VARCHAR(20)   NOT NULL,
    quantity        NUMERIC(14,3) NOT NULL,
    unit_cost       NUMERIC(14,4) NOT NULL DEFAULT 0,
    source_order_id UUID,
    notes           VARCHAR(255),
    moved_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_stock_movements PRIMARY KEY (id),
    CONSTRAINT ck_sm_store_code   CHECK (store_code ~ '^[0-9]{8}$'),
    CONSTRAINT ck_sm_type
        CHECK (movement_type IN ('CONSUMPTION', 'WASTE', 'ORDER_RECEIPT', 'ADJUSTMENT')),

    -- Convenção de sinal, explicitada para não restar dúvida:
    CONSTRAINT ck_sm_quantity_sign CHECK (
        (movement_type IN ('CONSUMPTION', 'WASTE') AND quantity < 0)
        OR
        (movement_type = 'ORDER_RECEIPT' AND quantity > 0)
        OR
        (movement_type = 'ADJUSTMENT' AND quantity <> 0)
    ),

    CONSTRAINT fk_sm_ingredient
        FOREIGN KEY (ingredient_id, store_code)
        REFERENCES bakery.ingredients (id, store_code)
);

COMMENT ON TABLE bakery.stock_movements IS
    'Livro-razão de estoque. Toda entrada e toda saída vira uma linha aqui. '
    'ingredients.computed_stock é o saldo denormalizado desta tabela.';
COMMENT ON COLUMN bakery.stock_movements.quantity IS
    'Quantidade em UNIDADE BASE, com sinal: negativa em CONSUMPTION/WASTE, positiva em ORDER_RECEIPT.';
COMMENT ON COLUMN bakery.stock_movements.unit_cost IS
    'Custo por UNIDADE BASE no momento do movimento.';
COMMENT ON COLUMN bakery.stock_movements.moved_at IS
    'Instante do movimento. Guardado como TIMESTAMPTZ; a operação da padaria acontece em America/Sao_Paulo.';


-- =============================================================================
-- Nota sobre índices
--
-- Este schema tem apenas os índices que vêm de graça com PRIMARY KEY e UNIQUE.
-- Isso é intencional. Se alguma consulta sua precisar de mais, crie o arquivo
-- `sql/03_indexes.sql` e justifique cada índice em comentário.
-- =============================================================================
