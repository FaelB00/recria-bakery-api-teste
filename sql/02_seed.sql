-- =============================================================================
-- Teste técnico Backend — massa de dados
--
-- NÃO EDITE ESTE ARQUIVO. A avaliação roda contra exatamente estes dados.
--
-- Duas lojas:
--   10000001  — Padaria Vila Nova
--   10000002  — Padaria Jardim Sul
--
-- Volume final: 10.410 linhas em bakery.stock_movements, cobrindo ~6 meses.
-- A geração é determinística: rodar de novo produz exatamente os mesmos dados.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Fornecedores
-- -----------------------------------------------------------------------------
INSERT INTO bakery.suppliers (id, store_code, name, contact_phone, is_active) VALUES
    ('11111111-0000-4000-8000-000000000001', '10000001', 'Moinho Aurora',          '5511900000001', TRUE),
    ('11111111-0000-4000-8000-000000000002', '10000001', 'Distribuidora Central',  '5511900000002', TRUE),
    ('11111111-0000-4000-8000-000000000003', '10000001', 'Distribuidora Central',  '5511900000003', TRUE),
    ('11111111-0000-4000-8000-000000000004', '10000001', 'Laticínios Vale Verde',  '5511900000004', TRUE),
    ('11111111-0000-4000-8000-000000000005', '10000001', 'Frutas do Sítio',        '5511900000005', TRUE),
    ('11111111-0000-4000-8000-000000000006', '10000001', 'Embalagens Norte',       '5511900000006', FALSE),

    ('22222222-0000-4000-8000-000000000001', '10000002', 'Moinho Aurora',          '5511800000001', TRUE),
    ('22222222-0000-4000-8000-000000000002', '10000002', 'Cooperativa do Leite',   '5511800000002', TRUE),
    ('22222222-0000-4000-8000-000000000003', '10000002', 'Grãos & Cia',            '5511800000003', TRUE),
    ('22222222-0000-4000-8000-000000000004', '10000002', 'Doces Insumos',          '5511800000004', TRUE),
    ('22222222-0000-4000-8000-000000000005', '10000002', 'Frigorífico Sul',        '5511800000005', TRUE),
    ('22222222-0000-4000-8000-000000000006', '10000002', 'Papelaria Industrial',   '5511800000006', FALSE);


-- -----------------------------------------------------------------------------
-- Insumos
-- -----------------------------------------------------------------------------
INSERT INTO bakery.ingredients
    (id, store_code, name, measure_unit, units_per_package, default_supplier_id, average_cost) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', '10000001', 'Farinha de Trigo Tipo 1', 'KG',  3.000, '11111111-0000-4000-8000-000000000001',  3.3333),
    ('aaaaaaaa-0000-4000-8000-000000000002', '10000001', 'Fermento Biológico Seco', 'KG',  0.500, '11111111-0000-4000-8000-000000000001', 42.0000),
    ('aaaaaaaa-0000-4000-8000-000000000003', '10000001', 'Açúcar Refinado',         'KG',  5.000, '11111111-0000-4000-8000-000000000002',  4.8000),
    ('aaaaaaaa-0000-4000-8000-000000000004', '10000001', 'Sal Refinado',            'KG',  1.000, '11111111-0000-4000-8000-000000000002',  2.1000),
    ('aaaaaaaa-0000-4000-8000-000000000005', '10000001', 'Manteiga sem Sal',        'KG',  2.500, '11111111-0000-4000-8000-000000000004', 38.5000),
    ('aaaaaaaa-0000-4000-8000-000000000006', '10000001', 'Leite Integral',          'L',  12.000, '11111111-0000-4000-8000-000000000004',  5.2000),
    ('aaaaaaaa-0000-4000-8000-000000000007', '10000001', 'Ovos',                    'UN', 30.000, '11111111-0000-4000-8000-000000000005',  0.9000),
    ('aaaaaaaa-0000-4000-8000-000000000008', '10000001', 'Chocolate em Pó',         'KG',  1.000, '11111111-0000-4000-8000-000000000003', 28.0000),
    ('aaaaaaaa-0000-4000-8000-000000000009', '10000001', 'Creme de Leite',          'L',  12.000, '11111111-0000-4000-8000-000000000004',  9.7000),
    ('aaaaaaaa-0000-4000-8000-000000000010', '10000001', 'Óleo de Soja',            'L',  20.000, '11111111-0000-4000-8000-000000000003',  7.4000),
    ('aaaaaaaa-0000-4000-8000-000000000011', '10000001', 'Fubá',                    'KG',  5.000, '11111111-0000-4000-8000-000000000001',  3.9000),
    ('aaaaaaaa-0000-4000-8000-000000000012', '10000001', 'Coco Ralado',             'KG',  1.000, '11111111-0000-4000-8000-000000000005', 22.0000),
    ('aaaaaaaa-0000-4000-8000-000000000013', '10000001', 'Goiabada',                'KG',  4.000, '11111111-0000-4000-8000-000000000005', 16.5000),
    ('aaaaaaaa-0000-4000-8000-000000000014', '10000001', 'Queijo Minas',            'KG',  1.000, '11111111-0000-4000-8000-000000000004', 41.0000),
    ('aaaaaaaa-0000-4000-8000-000000000015', '10000001', 'Presunto Fatiado',        'KG',  1.000, '11111111-0000-4000-8000-000000000004', 33.0000),

    ('bbbbbbbb-0000-4000-8000-000000000001', '10000002', 'Farinha de Trigo Tipo 1', 'KG',  3.000, '22222222-0000-4000-8000-000000000001',  3.3333),
    ('bbbbbbbb-0000-4000-8000-000000000002', '10000002', 'Farinha Integral',        'KG',  3.000, '22222222-0000-4000-8000-000000000001',  5.1000),
    ('bbbbbbbb-0000-4000-8000-000000000003', '10000002', 'Açúcar Mascavo',          'KG',  5.000, '22222222-0000-4000-8000-000000000003',  9.2000),
    ('bbbbbbbb-0000-4000-8000-000000000004', '10000002', 'Sal Grosso',              'KG',  1.000, '22222222-0000-4000-8000-000000000003',  1.8000),
    ('bbbbbbbb-0000-4000-8000-000000000005', '10000002', 'Manteiga com Sal',        'KG',  2.500, '22222222-0000-4000-8000-000000000002', 36.0000),
    ('bbbbbbbb-0000-4000-8000-000000000006', '10000002', 'Leite Desnatado',         'L',  12.000, '22222222-0000-4000-8000-000000000002',  4.9000),
    ('bbbbbbbb-0000-4000-8000-000000000007', '10000002', 'Ovos Caipira',            'UN', 20.000, '22222222-0000-4000-8000-000000000005',  1.6000),
    ('bbbbbbbb-0000-4000-8000-000000000008', '10000002', 'Cacau em Pó',             'KG',  1.000, '22222222-0000-4000-8000-000000000004', 35.0000),
    ('bbbbbbbb-0000-4000-8000-000000000009', '10000002', 'Nata',                    'L',  12.000, '22222222-0000-4000-8000-000000000002', 11.0000),
    ('bbbbbbbb-0000-4000-8000-000000000010', '10000002', 'Óleo de Girassol',        'L',  20.000, '22222222-0000-4000-8000-000000000004', 12.3000),
    ('bbbbbbbb-0000-4000-8000-000000000011', '10000002', 'Polvilho Doce',           'KG',  5.000, '22222222-0000-4000-8000-000000000003',  8.7000),
    ('bbbbbbbb-0000-4000-8000-000000000012', '10000002', 'Castanha de Caju',        'KG',  1.000, '22222222-0000-4000-8000-000000000004', 78.0000),
    ('bbbbbbbb-0000-4000-8000-000000000013', '10000002', 'Doce de Leite',           'KG',  4.000, '22222222-0000-4000-8000-000000000004', 19.5000),
    ('bbbbbbbb-0000-4000-8000-000000000014', '10000002', 'Queijo Coalho',           'KG',  1.000, '22222222-0000-4000-8000-000000000005', 44.0000),
    ('bbbbbbbb-0000-4000-8000-000000000015', '10000002', 'Linguiça Calabresa',      'KG',  1.000, '22222222-0000-4000-8000-000000000005', 29.0000);


-- -----------------------------------------------------------------------------
-- Pedidos de compra
--
-- Loja 10000001:
--   cccccccc-...0001  PLACED    — pronto para ser recebido
--   cccccccc-...0002  DRAFT     — ainda em edição
--   cccccccc-...0003  RECEIVED  — já recebido, com uma divergência registrada
-- Loja 10000002:
--   cccccccc-...0004  PLACED
-- -----------------------------------------------------------------------------
INSERT INTO bakery.purchase_orders
    (id, store_code, supplier_id, status, placed_at, received_at, total_cost) VALUES
    ('cccccccc-0000-4000-8000-000000000001', '10000001', '11111111-0000-4000-8000-000000000001',
     'PLACED',   TIMESTAMPTZ '2026-08-10 09:00:00-03', NULL, 0),
    ('cccccccc-0000-4000-8000-000000000002', '10000001', '11111111-0000-4000-8000-000000000002',
     'DRAFT',    NULL, NULL, 0),
    ('cccccccc-0000-4000-8000-000000000003', '10000001', '11111111-0000-4000-8000-000000000004',
     'RECEIVED', TIMESTAMPTZ '2026-08-01 09:00:00-03', TIMESTAMPTZ '2026-08-03 07:30:00-03', 0),
    ('cccccccc-0000-4000-8000-000000000004', '10000002', '22222222-0000-4000-8000-000000000001',
     'PLACED',   TIMESTAMPTZ '2026-08-11 10:00:00-03', NULL, 0);

INSERT INTO bakery.purchase_order_items
    (id, store_code, order_id, ingredient_id,
     ordered_package_qty, ordered_unit_qty, received_unit_qty, package_cost, status, divergence_status) VALUES
    -- Pedido PLACED da loja 1 — o alvo natural de um recebimento
    ('dddddddd-0000-4000-8000-000000000001', '10000001',
     'cccccccc-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000001',
     10.000, NULL, NULL, 10.0000, 'PLACED', NULL),
    ('dddddddd-0000-4000-8000-000000000002', '10000001',
     'cccccccc-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000003',
      4.000, NULL, NULL, 24.0000, 'PLACED', NULL),
    ('dddddddd-0000-4000-8000-000000000003', '10000001',
     'cccccccc-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000007',
     NULL, 90.000, NULL, 27.0000, 'PLACED', NULL),

    -- Pedido DRAFT da loja 1
    ('dddddddd-0000-4000-8000-000000000004', '10000001',
     'cccccccc-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-000000000008',
      3.000, NULL, NULL, 28.0000, 'DRAFT', NULL),
    ('dddddddd-0000-4000-8000-000000000005', '10000001',
     'cccccccc-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-000000000011',
     NULL, 25.000, NULL, 19.5000, 'DRAFT', NULL),

    -- Pedido RECEIVED da loja 1 — exemplo de como um item recebido fica
    ('dddddddd-0000-4000-8000-000000000006', '10000001',
     'cccccccc-0000-4000-8000-000000000003', 'aaaaaaaa-0000-4000-8000-000000000005',
      8.000, NULL, 20.000, 96.2500, 'RECEIVED', 'OK'),
    ('dddddddd-0000-4000-8000-000000000007', '10000001',
     'cccccccc-0000-4000-8000-000000000003', 'aaaaaaaa-0000-4000-8000-000000000006',
      5.000, NULL, 48.000, 62.4000, 'RECEIVED', 'DIVERGENT'),

    -- Pedido PLACED da loja 2
    ('dddddddd-0000-4000-8000-000000000008', '10000002',
     'cccccccc-0000-4000-8000-000000000004', 'bbbbbbbb-0000-4000-8000-000000000001',
      6.000, NULL, NULL, 10.0000, 'PLACED', NULL),
    ('dddddddd-0000-4000-8000-000000000009', '10000002',
     'cccccccc-0000-4000-8000-000000000004', 'bbbbbbbb-0000-4000-8000-000000000007',
     NULL, 40.000, NULL, 32.0000, 'PLACED', NULL);


-- -----------------------------------------------------------------------------
-- Livro-razão de estoque
-- -----------------------------------------------------------------------------

-- Cada insumo recebe um número de ordem (`ord`) que entra nas fórmulas abaixo,
-- para que os insumos não tenham históricos idênticos: quantidades, horários,
-- frequência de perda e custo variam de um para o outro.

-- 1) Saldo inicial de inventário (30 linhas)
INSERT INTO bakery.stock_movements
    (store_code, ingredient_id, movement_type, quantity, unit_cost, notes, moved_at)
SELECT
    i.store_code,
    i.id,
    'ADJUSTMENT',
    2500.000,
    i.average_cost,
    'Saldo inicial de inventário',
    TIMESTAMPTZ '2026-02-14 08:00:00-03'
FROM bakery.ingredients i;

-- 2) Consumo ao longo do expediente, com perdas esporádicas (4.200 linhas)
WITH ing AS (
    SELECT i.*, row_number() OVER (PARTITION BY i.store_code ORDER BY i.name)::int AS ord
    FROM bakery.ingredients i
)
INSERT INTO bakery.stock_movements
    (store_code, ingredient_id, movement_type, quantity, unit_cost, moved_at)
SELECT
    ing.store_code,
    ing.id,
    CASE WHEN ((g + ing.ord) % 11) = 0 THEN 'WASTE' ELSE 'CONSUMPTION' END,
    -1 * ((1 + ((g * ing.ord) % 9))::numeric + (ing.ord % 4) * 0.125 + 0.250),
    ROUND(ing.average_cost * (1 + ((g % 13) - 6) * 0.01), 4),
    TIMESTAMPTZ '2026-02-15 05:00:00-03'
        + (((g * 7 + ing.ord * 3) % 178) * INTERVAL '1 day')
        + (((g + ing.ord * 5) % 16) * INTERVAL '1 hour')
FROM ing
CROSS JOIN generate_series(1, 140) AS g;

-- 2b) Apontamento do fechamento, feito todo dia no fim do expediente
--     (5.340 linhas). Cada insumo tem seu horário fixo de conferência.
WITH ing AS (
    SELECT i.*, row_number() OVER (PARTITION BY i.store_code ORDER BY i.name)::int AS ord
    FROM bakery.ingredients i
)
INSERT INTO bakery.stock_movements
    (store_code, ingredient_id, movement_type, quantity, unit_cost, notes, moved_at)
SELECT
    ing.store_code,
    ing.id,
    CASE WHEN ((d + ing.ord) % 6) = 0 THEN 'WASTE' ELSE 'CONSUMPTION' END,
    -1 * ((1 + ((d * ing.ord) % 7))::numeric + 0.500),
    ROUND(ing.average_cost * (1 + ((d % 11) - 5) * 0.01), 4),
    'Apontamento do fechamento',
    TIMESTAMPTZ '2026-02-15 22:30:00-03'
        + (d * INTERVAL '1 day')
        + ((ing.ord % 2) * INTERVAL '1 hour')
FROM ing
CROSS JOIN generate_series(0, 177) AS d;

-- 3) Entradas de pedidos já recebidos no passado (840 linhas)
WITH ing AS (
    SELECT i.*, row_number() OVER (PARTITION BY i.store_code ORDER BY i.name)::int AS ord
    FROM bakery.ingredients i
)
INSERT INTO bakery.stock_movements
    (store_code, ingredient_id, movement_type, quantity, unit_cost, moved_at)
SELECT
    ing.store_code,
    ing.id,
    'ORDER_RECEIPT',
    (10 + ((g * ing.ord) % 7) * 5)::numeric,
    ROUND(ing.average_cost * (1 + ((g % 9) - 4) * 0.015), 4),
    TIMESTAMPTZ '2026-02-16 09:00:00-03' + (((g * 6 + ing.ord) % 176) * INTERVAL '1 day')
FROM ing
CROSS JOIN generate_series(1, 28) AS g;


-- -----------------------------------------------------------------------------
-- Reconcilia o saldo denormalizado com o livro-razão
-- -----------------------------------------------------------------------------
UPDATE bakery.ingredients i
SET computed_stock = agg.total
FROM (
    SELECT store_code, ingredient_id, SUM(quantity) AS total
    FROM bakery.stock_movements
    GROUP BY store_code, ingredient_id
) agg
WHERE i.id = agg.ingredient_id
  AND i.store_code = agg.store_code;


-- -----------------------------------------------------------------------------
-- Conferência (aparece no log do container quando o banco sobe pela 1ª vez)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_stores      INT;
    v_suppliers   INT;
    v_ingredients INT;
    v_orders      INT;
    v_movements   INT;
    v_min_stock   NUMERIC;
BEGIN
    SELECT count(DISTINCT store_code) INTO v_stores      FROM bakery.ingredients;
    SELECT count(*)                   INTO v_suppliers   FROM bakery.suppliers;
    SELECT count(*)                   INTO v_ingredients FROM bakery.ingredients;
    SELECT count(*)                   INTO v_orders      FROM bakery.purchase_orders;
    SELECT count(*)                   INTO v_movements   FROM bakery.stock_movements;
    SELECT min(computed_stock)        INTO v_min_stock   FROM bakery.ingredients;

    RAISE NOTICE 'seed ok | lojas=% fornecedores=% insumos=% pedidos=% movimentos=% menor_saldo=%',
        v_stores, v_suppliers, v_ingredients, v_orders, v_movements, v_min_stock;

    IF v_movements < 9000 THEN
        RAISE EXCEPTION 'seed incompleto: esperava >= 9000 movimentos, gerou %', v_movements;
    END IF;
    IF v_min_stock <= 0 THEN
        RAISE EXCEPTION 'seed inconsistente: algum insumo ficou com saldo <= 0 (%)', v_min_stock;
    END IF;
END $$;
