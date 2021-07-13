-- https://edu.datacraze.pl/zrozum-sql/modul-11-wydajnosc/lekcja-18-praca-domowa/?bpmj_eddpc_url=3UxGyKYvLZcWjigihujt4PI0vu0IQIOllNaObZIehkQ6gp%2BNIN8ScRike6lqq6chZGpkTSXybudWmGGWTVqW%2FcKHCOO7IDp1mgbKGEFza8RqNP%2BsEnz6XRE7mRQacmUy4iEbp%2B8Z5FZnEHNv7hBPXSjU2nlZBAFSjC37mXI7MDTPORdhqj0rIjWpgqer%2BoZ6tuzLVwTE%2F1k%3D

-- 1. Przygotuj zapytanie wyświetlające dane sprzedażowe za okres ostatnich 2 miesięcy
--    (skorzystaj ze składni INTERVAL). W wyniku wyświetl wszystkie atrybuty sprzedażowe
--    i dodatkowo nazwę i kod produktu oraz region, w którym produkt powstał.
--    Dane wyświetl wyłącznie dla kodu produktu równego PRD8
  
   SELECT s.*,
		  p.product_name,
		  p.product_code,
		  pmr.region_name 
     FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date > current_date - INTERVAL '2 months'
      AND p.product_code = 'PRD8';
   

-- 2. Korzystając z opcji EXPLAIN ANALYZE, przeanalizuj plan zapytania dla zapytania z
--    zadania 1. Rozpisz, z jakich elementów się składa: rodzaj użytego algorytmu, koszty na
--    poszczególnych etapach, jaki rodzaj pobierania danych został wykorzystany
--    (sekwencyjne skanowanie czy indeksy).

DISCARD ALL;   
   
EXPLAIN ANALYZE
   SELECT s.*,
		  p.product_name,
		  p.product_code,
		  pmr.region_name 
     FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date > current_date - INTERVAL '2 months'
      AND p.product_code = 'PRD8';
     
--QUERY PLAN                                                                                                                                   |
-----------------------------------------------------------------------------------------------------------------------------------------------|
--Hash Join  (cost=30.79..348.79 rows=142 width=372) (actual time=0.071..6.141 rows=1041 loops=1)                                              |
--  Hash Cond: (s.sal_prd_id = p.id)                                                                                                           |
--  ->  Seq Scan on sales s  (cost=0.00..279.00 rows=10000 width=48) (actual time=0.022..4.585 rows=10000 loops=1)                             |
--        Filter: (sal_date > (CURRENT_DATE - '2 mons'::interval))                                                                             |
--  ->  Hash  (cost=30.75..30.75 rows=3 width=328) (actual time=0.040..0.042 rows=1 loops=1)                                                   |
--        Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                         |
--        ->  Hash Right Join  (cost=12.89..30.75 rows=3 width=328) (actual time=0.033..0.039 rows=1 loops=1)                                  |
--              Hash Cond: (pmr.id = p.product_man_region)                                                                                     |
--              ->  Seq Scan on product_manufactured_region pmr  (cost=0.00..15.70 rows=570 width=72) (actual time=0.008..0.009 rows=5 loops=1)|
--              ->  Hash  (cost=12.88..12.88 rows=1 width=264) (actual time=0.019..0.019 rows=1 loops=1)                                       |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                             |
--                    ->  Seq Scan on products p  (cost=0.00..12.88 rows=1 width=264) (actual time=0.013..0.014 rows=1 loops=1)                |
--                          Filter: ((product_code)::text = 'PRD8'::text)                                                                      |
--                          Rows Removed by Filter: 9                                                                                          |
--Planning Time: 0.222 ms                                                                                                                      |
--Execution Time: 6.205 ms                                                                                                                     |                                                                                                                   |                                                                                                |
   
--1. Hash Join, koszt startowy (KS) 30.79, koszt całkowity (KC) 348.79 dla warunku s.id = p.id
--2. Skan sekwencyjny na tabeli sales, KS 0, KC 279; filtrowanie atrybutów sal_date
--3. Funkcja hashująca, KS 30.75, KC 30.75 (tutaj widać redukcję liczby wierszy do trzech)
--4. Hash Right Join, KS 12.98, KC 30.75 dla warunku pmr.id = p.product_man_region 
--  **dlaczego jest tutaj right join? od czego zależy jaki join zostanie użyty?**
--5. Skan sekwencyjny na tabeli product_manufactured_region, KS 0.00, KC 15.70
--6. Funkcja hashująca, KS 12.88, KC 12.88
--7. Skan sekwencyjny na tabeli products, KS 0.00, KC 12.88; filtrowanie atrubutów product_code

     
-- 3. Oblicz miarę selektywności dla atrybutu PRODUCT_CODE z tabeli PRODUCTS.

SELECT count(DISTINCT product_code) distinct_products,
	   count(*) rows_in_table,
	   count(DISTINCT product_code)::float/count(*) selectivity_index
  FROM products;
 
-- selectivity_index = 0.8

-- 4. Dodaj indeks do tabeli PRODUCTS na polu PRODUCT_CODE typu BTREE.

DROP INDEX IF EXISTS idx_product_code;

CREATE INDEX idx_product_code
          ON products
       USING BTREE (product_code);
 
-- 5. Zweryfikuj plan wykonania zapytania dla zapytania z zadania 1 po dodaniu indeksu. Czy
--    indeks został użyty?

DISCARD ALL;

EXPLAIN ANALYZE
   SELECT s.*,
		  p.product_name,
		  p.product_code,
		  pmr.region_name 
     FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date > current_date - INTERVAL '2 months'
      AND p.product_code = 'PRD8';
   
--QUERY PLAN                                                                                                                                   |
-----------------------------------------------------------------------------------------------------------------------------------------------|
--Hash Join  (cost=19.04..390.54 rows=2850 width=372) (actual time=0.104..7.518 rows=1041 loops=1)                                             |
--  Hash Cond: (s.sal_prd_id = p.id)                                                                                                           |
--  ->  Seq Scan on sales s  (cost=0.00..279.00 rows=10000 width=48) (actual time=0.028..5.581 rows=10000 loops=1)                             |
--        Filter: (sal_date > (CURRENT_DATE - '2 mons'::interval))                                                                             |
--  ->  Hash  (cost=19.00..19.00 rows=3 width=328) (actual time=0.062..0.064 rows=1 loops=1)                                                   |
--        Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                         |
--        ->  Hash Right Join  (cost=1.14..19.00 rows=3 width=328) (actual time=0.051..0.060 rows=1 loops=1)                                   |
--              Hash Cond: (pmr.id = p.product_man_region)                                                                                     |
--              ->  Seq Scan on product_manufactured_region pmr  (cost=0.00..15.70 rows=570 width=72) (actual time=0.011..0.012 rows=5 loops=1)|
--              ->  Hash  (cost=1.13..1.13 rows=1 width=264) (actual time=0.031..0.031 rows=1 loops=1)                                         |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                             |
--                    ->  Seq Scan on products p  (cost=0.00..1.13 rows=1 width=264) (actual time=0.022..0.024 rows=1 loops=1)                 |
--                          Filter: ((product_code)::text = 'PRD8'::text)                                                                      |
--                          Rows Removed by Filter: 9                                                                                          |
--Planning Time: 0.278 ms                                                                                                                      |
--Execution Time: 7.607 ms                                                                                                                     |                                                                                                                    |
   
-- index nie został wykorzystany

-- 6. Dodaj indeks dla daty sprzedaży (SAL_DATE) na tabeli SALES. 

DROP INDEX IF EXISTS idx_sal_date;

CREATE INDEX idx_sal_date
          ON sales
       USING BTREE (sal_date);
      
-- 7. Zweryfikuj plan wykonania zapytania dla zapytania z zadania 1 po dodaniu indeksu. Czy
--    indeks dla SAL_DATE lub PRODUCT_CODE został użyty?

DISCARD ALL;

EXPLAIN ANALYZE
   SELECT s.*,
		  p.product_name,
		  p.product_code,
		  pmr.region_name 
     FROM sales s
LEFT JOIN products p ON s.sal_prd_id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date > current_date - INTERVAL '2 months'
      AND p.product_code = 'PRD8';

     
--QUERY PLAN                                                                                                                                   |
-----------------------------------------------------------------------------------------------------------------------------------------------|
--Hash Join  (cost=19.04..390.54 rows=2850 width=372) (actual time=0.089..7.526 rows=1041 loops=1)                                             |
--  Hash Cond: (s.sal_prd_id = p.id)                                                                                                           |
--  ->  Seq Scan on sales s  (cost=0.00..279.00 rows=10000 width=48) (actual time=0.025..5.593 rows=10000 loops=1)                             |
--        Filter: (sal_date > (CURRENT_DATE - '2 mons'::interval))                                                                             |
--  ->  Hash  (cost=19.00..19.00 rows=3 width=328) (actual time=0.050..0.055 rows=1 loops=1)                                                   |
--        Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                         |
--        ->  Hash Right Join  (cost=1.14..19.00 rows=3 width=328) (actual time=0.039..0.051 rows=1 loops=1)                                   |
--              Hash Cond: (pmr.id = p.product_man_region)                                                                                     |
--              ->  Seq Scan on product_manufactured_region pmr  (cost=0.00..15.70 rows=570 width=72) (actual time=0.009..0.010 rows=5 loops=1)|
--              ->  Hash  (cost=1.13..1.13 rows=1 width=264) (actual time=0.023..0.024 rows=1 loops=1)                                         |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                             |
--                    ->  Seq Scan on products p  (cost=0.00..1.13 rows=1 width=264) (actual time=0.017..0.018 rows=1 loops=1)                 |
--                          Filter: ((product_code)::text = 'PRD8'::text)                                                                      |
--                          Rows Removed by Filter: 9                                                                                          |
--Planning Time: 0.849 ms                                                                                                                      |
--Execution Time: 7.620 ms           

-- w tym przypadku również indeksy nie zostąły wykorzystane
     
-- 8. Na podstawie instrukcji poniżej zweryfikuj czy partycjonowanie tabeli ma istotny wpływ
--    na plan wykonania zapytania i operację INSERT. (ten skrypt znajduje się również w linku
--    powyżej).

DROP TABLE IF EXISTS sales, sales_partitioned CASCADE;

CREATE TABLE sales (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);
 
 
CREATE TABLE sales_partitioned (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
) PARTITION BY RANGE (sal_date);

CREATE TABLE sales_y2018 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE sales_y2019 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
   
CREATE TABLE sales_y2020 PARTITION OF sales_partitioned
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
   
CREATE TABLE sales_y2021 PARTITION OF sales_partitioned
	FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

EXPLAIN ANALYZE
INSERT INTO sales (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 1000000) s(i);    
      
--QUERY PLAN                                                                                                                                      |
--------------------------------------------------------------------------------------------------------------------------------------------------|
--Insert on sales  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=19815.400..19815.402 rows=0 loops=1)                                 |
--  ->  Subquery Scan on "*SELECT*"  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=243.498..15614.266 rows=1000000 loops=1)           |
--        ->  Function Scan on generate_series s  (cost=0.00..50000.00 rows=1000000 width=52) (actual time=243.334..7111.260 rows=1000000 loops=1)|
--Planning Time: 0.136 ms                                                                                                                         |
--Execution Time: 19821.403 ms                                                                                                                    |                                                                                                                 |      

DISCARD ALL;      
EXPLAIN ANALYZE
INSERT INTO sales_partitioned (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 1000000) s(i);                                                                                                             

      
--QUERY PLAN                                                                                                                                      |
--------------------------------------------------------------------------------------------------------------------------------------------------|
--Insert on sales_partitioned  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=19931.543..19931.546 rows=0 loops=1)                     |
--  ->  Subquery Scan on "*SELECT*"  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=308.016..15294.107 rows=1000000 loops=1)           |
--        ->  Function Scan on generate_series s  (cost=0.00..50000.00 rows=1000000 width=52) (actual time=307.870..7057.309 rows=1000000 loops=1)|
--Planning Time: 0.137 ms                                                                                                                         |
--Execution Time: 19938.246 ms                                                                                                                    |        

-- Czas wykonania dla tabeli bez i z partycjonowaniem jest w przybliżeniu taki sam.
-- Na tej podstawie można wywnioskować, że w tym przypadku partycjonowanie nie wpłynęło
-- ani na plan wykonania zapytania dla operajci INSERT, ani na czas jego wykonania.

