-- Przygotowanie - korzystając ze skryptu poniżej utwórz obiekty potrzebne do zadania.
-- https://github.com/morb1d/zrozumsql/blob/master/zs_exercises/M9_L13_SAMPLE_DATA_FOR_THEORY_EXERCISES.sql
-- W skryptach do sprawdzenia, nie podawaj proszę wartości wynikowych tylko samą składnię
-- z ewentualnym opisem.
--
--1. Przygotuj widok bazodanowy na podstawie danych sprzedażowych SALES, który będzie
--   przedstawiał dane za ostatni kwartał roku 2020, dla wszystkich produktów biorących
--   udział w transakcjach sprzedażowych wytworzonych w regionie EMEA.
     
CREATE OR REPLACE VIEW products_Q1_2020_EMEA AS 
	   SELECT p.product_name,
	   		  p.product_code,
	   		  p.product_quantity,
	   		  p.manufactured_date,
	   		  s.sal_date,
	   		  s.sal_value 
	     FROM sales s
	LEFT JOIN products p ON p.id = s.sal_prd_id 
	     JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region 
	    WHERE pmr.region_name = 'EMEA'
    	      AND EXTRACT(QUARTER FROM sal_date) = 1;
-- w tabeli sales mam dane tylko z pierwszego kwartału, dlatego wybrałem go w ćwiczeniu

SELECT * FROM products_Q1_2020_EMEA;

--DROP VIEW * FROM products_Q1_2020_EMEA
   
-- 2. Zmień zapytanie z zadania pierwszego w taki sposób, aby w wynikach dodatkowo,
--    obliczyć sumę sprzedaży w podziale na kod produktu (product_code) sortowane według
--    daty sprzedaży (sal_date), wynik wyświetl dla każdego wiersza (OVER). Tak
--    przygotowane zapytanie wykorzystaj do stworzenia widoku zmaterializowanego, który
--    będzie mógł być odświeżany równolegle (CONCURRENTLY).

	   SELECT p.product_code,
	   		  s.sal_date,
	   		  sum(s.sal_value) OVER (PARTITION BY p.product_code) cumsum_prd_code
	     FROM sales s
	LEFT JOIN products p ON p.id = s.sal_prd_id 
	     JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region 
	    WHERE pmr.region_name = 'EMEA'
    	      AND EXTRACT(QUARTER FROM sal_date) = 1
     ORDER BY s.sal_date;
    	     
CREATE MATERIALIZED VIEW products_cumsum_prd_code AS 
	   SELECT ROW_NUMBER() OVER (ORDER BY s.sal_date, p.product_code, s.sal_value) AS id,
	   		  p.product_code,
	   		  s.sal_date,
	   		  sum(s.sal_value) OVER (PARTITION BY p.product_code) cumsum_prd_code
	     FROM sales s
	LEFT JOIN products p ON p.id = s.sal_prd_id 
	     JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region 
	    WHERE pmr.region_name = 'EMEA'
    	      AND EXTRACT(QUARTER FROM sal_date) = 1
       WITH DATA;

      
CREATE UNIQUE INDEX products_unq_id_mv ON products_cumsum_prd_code (id);      

SELECT * FROM products_cumsum_prd_code;

REFRESH MATERIALIZED VIEW CONCURRENTLY products_cumsum_prd_code;

--DROP MATERIALIZED VIEW products_cumsum_prd_code;

-- 3. Stwórz zapytanie, w którego wynikach znajdą się atrybuty: PRODUCT_CODE,
--    REGION_NAME i tablica zawierają nazwy produktów (PRODUCT_NAME) dla
--    wszystkich produktów z tabeli PRODUCTS.

   SELECT p.product_code,
	      pmr.region_name,
	      array_agg(p.product_name)
     FROM products p 
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
 GROUP BY p.product_code, pmr.region_name; 

-- 4. Dla zapytania z zdania 3 stwórz nową tabelę korzystając z konstrukcji CTAS. Dodaj
--    dodatkowo do nowej tabeli 1 kolumnę zawierającą wartość TRUE lub FALSE obliczaną
--    na podstawie danych z atrybutu tablicy nazw produktów dla kodu i regionu (zadanie 3)
--    w taki sposób, że gdy tablica zawiera więcej niż 1 element wartość ma być TRUE, w
--    przeciwnym razie FALSE.

CREATE TABLE IF NOT EXISTS products_region_name AS
	   SELECT p.product_code,
			  pmr.region_name,
			  p.product_name
	   	 FROM products p
	LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region;
	
SELECT * FROM products_region_name;

-- sprawdzamy czy tabela istnieje w schemacie public:
SELECT *
  FROM information_schema."columns" c 
 WHERE c.table_name = 'products_region_name'


-- 5. Stwórz nową tabelę SALES_ARCHIVE (jako zwykły CREATE TABLE nie CTAS), która
--    będzie miała strukturę na podstawie tabeli SALES z wyjątkami:
--    - nowy atrybut: operation_type VARCHAR(1) NOT NULL
--    - nowy atrybut: archived_at TIMESTAMP z automatycznym przypisywaniem
--      wartości NOW()
--    - atrybut created_date powinien być usunięty


CREATE TABLE IF NOT EXISTS sales_archive (
	id SERIAL NOT NULL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10, 2),
	sal_prd_id int4,
	added_by TEXT,
	operation_type VARCHAR(100) NOT NULL,
	archived_at TIMESTAMP DEFAULT NOW() 
)


-- 6. Dla tabeli stworzonej w zadaniu 5, utwórz TRIGGER + FUNKCJE DLA TRIGGERA, który
--    w momencie usuwania, lub aktualizacji wierszy w tabeli SALES, wstawi informację o
--    poprzedniej wartości do tabeli SALES_ARCHIVE. Po przypisaniu TRIGGERA, usuń z
--    tabeli SALES wszystkie dane sprzedażowe z Października 2020 (10.2020).

CREATE FUNCTION sales_archive_function()
	RETURNS TRIGGER
	LANGUAGE plpgsql
	AS $$
	BEGIN 
		IF (TG_OP = 'DELETE') THEN
			INSERT INTO sales_archive (operation_type, sal_description, sal_date, sal_value, sal_prd_id, added_by)
				VALUES ('DELETED', OLD.sal_description, OLD.sal_date, OLD.sal_value, OLD.sal_prd_id, OLD.added_by);
		ELSIF(TG_OP = 'UPDATE') THEN
				INSERT INTO sales_archive (operation_type, sal_description, sal_date, sal_value, sal_prd_id, added_by)
					VALUES ('UPDATED', OLD.sal_description, OLD.sal_date, OLD.sal_value, OLD.sal_prd_id, OLD.added_by);
		END IF;
		RETURN NULL;
	END;
	$$;

CREATE TRIGGER sales_archive_trigger
	AFTER UPDATE OR DELETE 
		ON sales
	FOR EACH ROW 
		EXECUTE PROCEDURE sales_archive_function();

-- sprawdzenie, czy funkcja istnieje
SELECT *
  FROM information_schema."routines" r 
 WHERE specific_name LIKE '%sales_archive_function%';
	
-- sprawdzenie, czy trigger istnieje
SELECT *
  FROM information_schema.triggers t;
  
-- usunięcie rekordów z tabeli sales (data dopasowana do dat w mojej tabeli: 2021-3)
DELETE 
  FROM sales s
 WHERE CONCAT(EXTRACT(YEAR FROM s.created_date), '-', EXTRACT(MONTH FROM s.created_date)) = '2021-3';

-- sprawdzenie, czy trigger dodał rekordy do sales_archive
SELECT *
  FROM sales_archive;
