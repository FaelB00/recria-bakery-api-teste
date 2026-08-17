-- Índices para o relatório GET /v1/reports/ingredients (item D3).
-- Baseado em EXPLAIN (ANALYZE, BUFFERS) real: 2779 buffers totais, sendo 2621
-- (~94%) da subquery de last_unit_cost, que rodava Seq Scan 17x (uma por insumo).
 
-- Acelera a subquery de last_unit_cost: ingredient_id + store_code + moved_at
-- já ordenado, evitando Seq Scan + Sort a cada execução.
CREATE INDEX idx_stock_movements_ingredient_store_moved_at
    ON bakery.stock_movements (ingredient_id, store_code, moved_at DESC);
 
-- Para o JOIN principal (filtrado por store_code + período). No EXPLAIN pós-
-- índice, o planner manteve Seq Scan aqui: a faixa cobre ~metade da tabela
-- (5205 de 10410 linhas), e nesse caso ler sequencialmente é mais barato que
-- usar o índice. Mantido para lojas/períodos mais seletivos, onde compensa.
CREATE INDEX idx_stock_movements_store_moved_at
    ON bakery.stock_movements (store_code, moved_at);
 