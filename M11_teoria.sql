-- https://edu.datacraze.pl/zrozum-sql/modul-11-wydajnosc/lekcja-18-praca-domowa/?bpmj_eddpc_url=3UxGyKYvLZcWjigihujt4PI0vu0IQIOllNaObZIehkQ6gp%2BNIN8ScRike6lqq6chZGpkTSXybudWmGGWTVqW%2FcKHCOO7IDp1mgbKGEFza8RqNP%2BsEnz6XRE7mRQacmUy4iEbp%2B8Z5FZnEHNv7hBPXSjU2nlZBAFSjC37mXI7MDTPORdhqj0rIjWpgqer%2BoZ6tuzLVwTE%2F1k%3D

-- 1. Przygotuj zapytanie wyświetlające dane sprzedażowe za okres ostatnich 2 miesięcy
--    (skorzystaj ze składni INTERVAL). W wyniku wyświetl wszystkie atrybuty sprzedażowe
--    i dodatkowo nazwę i kod produktu oraz region, w którym produkt powstał.
--    Dane wyświetl wyłącznie dla kodu produktu równego PRD8


   SELECT *,
		  p.product_name,
		  p.product_code,
		  pmr.region_name 
     FROM sales s
LEFT JOIN products p ON s.id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date BETWEEN (now()::date - INTERVAL '2 months') AND now()::date;
   
-- 2. Korzystając z opcji EXPLAIN ANALYZE, przeanalizuj plan zapytania dla zapytania z
--    zadania 1. Rozpisz, z jakich elementów się składa: rodzaj użytego algorytmu, koszty na
--    poszczególnych etapach, jaki rodzaj pobierania danych został wykorzystany
--    (sekwencyjne skanowanie czy indeksy).

DISCARD ALL;   
   
EXPLAIN ANALYZE
   SELECT *,
		  p.product_name,
		  p.product_code
     FROM sales s
LEFT JOIN products p ON s.id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date BETWEEN (now()::date - INTERVAL '2 months') AND now()::date;
   
--QUERY PLAN                                                                                                                        |
------------------------------------------------------------------------------------------------------------------------------------|
--Hash Right Join  (cost=301.24..322.30 rows=108 width=794) (actual time=7.345..8.936 rows=10000 loops=1)                           |
--  Hash Cond: (pmr.id = p.product_man_region)                                                                                      |
--  ->  Seq Scan on product_manufactured_region pmr  (cost=0.00..15.70 rows=570 width=114) (actual time=0.015..0.016 rows=5 loops=1)|
--  ->  Hash  (cost=300.77..300.77 rows=38 width=424) (actual time=7.321..7.322 rows=10000 loops=1)                                 |
--        Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 1066kB                                         |
--        ->  Hash Left Join  (cost=15.18..300.77 rows=38 width=424) (actual time=0.032..5.463 rows=10000 loops=1)                  |
--              Hash Cond: (s.id = p.id)                                                                                            |
--              ->  Seq Scan on sales s  (cost=0.00..284.18 rows=33 width=100) (actual time=0.016..3.878 rows=10000 loops=1)        |
--                    Filter: ((sal_date <= (now())::date) AND (sal_date >= ((now())::date - '2 mons'::interval)))                  |
--              ->  Hash  (cost=12.30..12.30 rows=230 width=324) (actual time=0.010..0.011 rows=10 loops=1)                         |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                  |
--                    ->  Seq Scan on products p  (cost=0.00..12.30 rows=230 width=324) (actual time=0.006..0.007 rows=10 loops=1)  |
--Planning Time: 0.169 ms                                                                                                           |
--Execution Time: 9.281 ms                                                                                                          |
   
--Hash RIGHT JOIN (cost=59115.18..68030.27 rows=2850000 width=486)
--|_Hash RIGHT JOIN (cost=15.18..55.25 rows=656 width=438) dla warunku pmr.id = p.product_man_region
--|  |_Skan sekwencyjny na tabeli product_manufactured_region (cost=0.00..15.70 rows=570 width=114)
--|  |_Funkcja hashujaca (cost=12.30..12.30 rows=230 width=324)
--|    |_Skan sekwencyjny na tabeli products (cost=0.00..12.30 rows=230 width=324)
--|_Funkcja hashujaca (cost=37810.00..37810.00 rows=1000000 width=48)
--  |_Skan sekwencyjny na tabeli sales (cost=0.00..37810.00 rows=1000000 width=48)
--    |_Filtrowanie wyników dla zadanego warunku 


--DISCARD ALL;
--EXPLAIN ANALYZE 
--WITH sales_2_months_old AS (
--	SELECT *
--	FROM sales s
--	WHERE s.sal_date BETWEEN now()::date - INTERVAL '2 months' AND now() ::date
--)
--SELECT *
--FROM sales_2_months_old s_2m
--LEFT JOIN products p ON p.id = s_2m.id
--LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region;

-- 3. Oblicz miarę selektywności dla atrybutu PRODUCT_CODE z tabeli PRODUCTS.

SELECT count(DISTINCT product_code) distinct_products,
	   count(*) rows_in_table,
	   count(DISTINCT product_code)::float/count(*) selectivity_index
  FROM products;

-- 4. Dodaj indeks do tabeli PRODUCTS na polu PRODUCT_CODE typu BTREE.

CREATE INDEX idx_product_code
          ON products
       USING BTREE (product_code);
 
-- 5. Zweryfikuj plan wykonania zapytania dla zapytania z zadania 1 po dodaniu indeksu. Czy
--    indeks został użyty?
DISCARD ALL;
DROP INDEX IF EXISTS idx_product_code;
DROP INDEX IF EXISTS idx_sal_date;

EXPLAIN ANALYZE
   SELECT *,
		  p.product_name,
		  p.product_code,
		  pmr.region_name 
     FROM sales s
LEFT JOIN products p ON s.id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date BETWEEN (now()::date - INTERVAL '2 months') AND now()::date;
   
--QUERY PLAN                                                                                                                                    |
------------------------------------------------------------------------------------------------------------------------------------------------|
--Hash Left Join  (cost=19.69..461.47 rows=28500 width=810) (actual time=0.049..6.048 rows=10000 loops=1)                                       |
--  Hash Cond: (s.id = p.id)                                                                                                                    |
--  ->  Seq Scan on sales s  (cost=0.00..379.00 rows=10000 width=48) (actual time=0.013..4.042 rows=10000 loops=1)                              |
--        Filter: ((sal_date <= (now())::date) AND (sal_date >= ((now())::date - '2 mons'::interval)))                                          |
--  ->  Hash  (cost=19.34..19.34 rows=28 width=438) (actual time=0.030..0.031 rows=10 loops=1)                                                  |
--        Buckets: 1024  Batches: 1  Memory Usage: 10kB                                                                                         |
--        ->  Hash Right Join  (cost=1.23..19.34 rows=28 width=438) (actual time=0.018..0.026 rows=10 loops=1)                                  |
--              Hash Cond: (pmr.id = p.product_man_region)                                                                                      |
--              ->  Seq Scan on product_manufactured_region pmr  (cost=0.00..15.70 rows=570 width=114) (actual time=0.005..0.005 rows=5 loops=1)|
--              ->  Hash  (cost=1.10..1.10 rows=10 width=324) (actual time=0.010..0.010 rows=10 loops=1)                                        |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                              |
--                    ->  Seq Scan on products p  (cost=0.00..1.10 rows=10 width=324) (actual time=0.006..0.007 rows=10 loops=1)                |
--Planning Time: 0.457 ms                                                                                                                       |
--Execution Time: 6.284 ms                                                                                                                      |
   
-- index nie został użyty, ale z jakiegoś powodu hash right join zmienił się na hash left join?

-- 6. Dodaj indeks dla daty sprzedaży (SAL_DATE) na tabeli SALES. 

CREATE INDEX idx_sal_date
          ON sales
       USING BTREE (sal_date);
      
-- 7. Zweryfikuj plan wykonania zapytania dla zapytania z zadania 1 po dodaniu indeksu. Czy
--    indeks dla SAL_DATE lub PRODUCT_CODE został użyty?
DISCARD ALL;
EXPLAIN ANALYZE
   SELECT *,
		  p.product_name,
		  p.product_code,
		  pmr.region_name 
     FROM sales s
LEFT JOIN products p ON s.id = p.id
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
    WHERE s.sal_date BETWEEN (now()::date - INTERVAL '2 months') AND now()::date;

   
--QUERY PLAN                                                                                                                                    |
------------------------------------------------------------------------------------------------------------------------------------------------|
--Hash Left Join  (cost=19.69..461.47 rows=28500 width=810) (actual time=0.043..5.393 rows=10000 loops=1)                                       |
--  Hash Cond: (s.id = p.id)                                                                                                                    |
--  ->  Seq Scan on sales s  (cost=0.00..379.00 rows=10000 width=48) (actual time=0.012..3.611 rows=10000 loops=1)                              |
--        Filter: ((sal_date <= (now())::date) AND (sal_date >= ((now())::date - '2 mons'::interval)))                                          |
--  ->  Hash  (cost=19.34..19.34 rows=28 width=438) (actual time=0.027..0.029 rows=10 loops=1)                                                  |
--        Buckets: 1024  Batches: 1  Memory Usage: 10kB                                                                                         |
--        ->  Hash Right Join  (cost=1.23..19.34 rows=28 width=438) (actual time=0.016..0.024 rows=10 loops=1)                                  |
--              Hash Cond: (pmr.id = p.product_man_region)                                                                                      |
--              ->  Seq Scan on product_manufactured_region pmr  (cost=0.00..15.70 rows=570 width=114) (actual time=0.004..0.005 rows=5 loops=1)|
--              ->  Hash  (cost=1.10..1.10 rows=10 width=324) (actual time=0.009..0.010 rows=10 loops=1)                                        |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                              |
--                    ->  Seq Scan on products p  (cost=0.00..1.10 rows=10 width=324) (actual time=0.005..0.006 rows=10 loops=1)                |
--Planning Time: 0.467 ms                                                                                                                       |
--Execution Time: 5.610 ms                                                                                                                      |
                                                                                                                 |
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
      
--QUERY PLAN                                                                                                                                     |
-------------------------------------------------------------------------------------------------------------------------------------------------|
--Insert on sales  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=5730.146..5730.146 rows=0 loops=1)                                  |
--  ->  Subquery Scan on "*SELECT*"  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=84.769..3720.246 rows=1000000 loops=1)            |
--        ->  Function Scan on generate_series s  (cost=0.00..50000.00 rows=1000000 width=52) (actual time=84.705..1718.844 rows=1000000 loops=1)|
--Planning Time: 0.068 ms                                                                                                                        |
--Execution Time: 5732.281 ms                                                                                                                    |      

EXPLAIN ANALYZE
INSERT INTO sales_partitioned (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 1000000) s(i);                                                                                                             

--QUERY PLAN                                                                                                                                     |
-------------------------------------------------------------------------------------------------------------------------------------------------|
--Insert on sales_partitioned  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=6101.746..6101.746 rows=0 loops=1)                      |
--  ->  Subquery Scan on "*SELECT*"  (cost=0.00..77500.00 rows=1000000 width=100) (actual time=84.501..3770.475 rows=1000000 loops=1)            |
--        ->  Function Scan on generate_series s  (cost=0.00..50000.00 rows=1000000 width=52) (actual time=84.444..1741.772 rows=1000000 loops=1)|
--Planning Time: 0.076 ms                                                                                                                        |
--Execution Time: 6103.831 ms          

-- W wyniku partycjonowania czas potrzebny na wykonanie operacji wydłużył się o ok. 400 ms,
-- ale wykonując kolejne próby można zauważyć, że najczęściej pojawia się wartość ok. 5700 ms,
-- a zatem zbliżona do zapytania bez partycjonowania.
-- Wniosek: partycjonowanie nie wpłynęło na szybkość wykonania zapytania.

