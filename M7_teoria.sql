DROP TABLE IF EXISTS products, sales, product_manufactured_region CASCADE;

CREATE TABLE products (
	id SERIAL,
	product_name VARCHAR(100),
	product_code VARCHAR(10),
	product_quantity NUMERIC(10,2),	
	manufactured_date DATE,
	product_man_region INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);

CREATE TABLE sales (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_prd_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);

DROP TABLE IF EXISTS product_manufactured_region;
CREATE TABLE product_manufactured_region (
	id SERIAL,
	region_name VARCHAR(25),
	region_code VARCHAR(10),
	established_year INTEGER
);

INSERT INTO product_manufactured_region (region_name, region_code, established_year)
	  VALUES ('EMEA', 'E_EMEA', 2010),
	  		 ('EMEA', 'W_EMEA', 2012),
	  		 ('APAC', NULL, 2019),
	  		 ('North America', NULL, 2012),
	  		 ('Africa', NULL, 2012);

INSERT INTO products (product_name, product_code, product_quantity, manufactured_date, product_man_region)
     SELECT 'Product '||floor(random() * 10 + 1)::int,
            'PRD'||floor(random() * 10 + 1)::int,
            random() * 10 + 1,
            CAST((NOW() - (random() * (interval '90 days')))::timestamp AS date),
            CEIL(random()*(10-5))::int
       FROM generate_series(1, 10) s(i);  
      
INSERT INTO sales (sal_description, sal_date, sal_value, sal_prd_id)
     SELECT left(md5(i::text), 15),
     		CAST((NOW() - (random() * (interval '60 days'))) AS DATE),	
     		random() * 100 + 1,
        	floor(random() * 10)+1::int            
       FROM generate_series(1, 10000) s(i);  
       
-- 1.  Korzystając z konstrukcji INNER JOIN połącz dane sprzedażowe (SALES, sal_prd_id) z
--     danymi o produktach (PRODUCTS, id). W wynikach pokaż tylko te produkty, które
--     powstały w regionie EMEA. Wyniki ogranicz do 100 wierszy.

      WITH products_products_manufactured_region AS 
	       (
	       SELECT p.*,
		          pmr.region_name
	         FROM products p
	   INNER JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
	        WHERE pmr.region_name = 'EMEA'
	       )
    SELECT ppmr.product_name,
		   ppmr.product_code,
		   ppmr.region_name,
		   s.id,
		   s.sal_description,
		   s.sal_date,
		   s.sal_value,
		   s.added_by,
		   s.created_date
      FROM sales s
INNER JOIN products_products_manufactured_region ppmr ON s.sal_prd_id = ppmr.id
     LIMIT 100;

-- wersja poprawiona (CTE jest niepotrzebne przy krótkich zapytaniach):

      SELECT s.*,
	         p.*,
	         pmr.*
        FROM sales s
  INNER JOIN products p ON s.sal_prd_id = p.id
  INNER JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
               								    AND pmr.region_name = 'EMEA'
       LIMIT 100;
	 
-- 2. Korzystając z konstrukcji LEFT JOIN połącz dane o produktach (PRODUCTS,
--    product_man_region) z danymi o regionach w których produkty powstały
--    (PRODUCT_MANUFACTURED_REGION, id)
--    W wynikach wyświetl wszystkie atrybuty z tabeli produktów i atrybut REGION_NAME
--    z tabeli PRODUCT_MANUFACTURED_REGION. Dodatkowo w trakcie złączenia
--    ogranicz dane brane przy złączenia do tych regionów, które zostały założone po 2012
--    roku.

   SELECT p.*,
	      pmr.region_name
     FROM products p
LEFT JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id
	  AND pmr.established_year > 2012;


-- 3. Korzystając z konstrukcji LEFT JOIN połącz dane o produktach (PRODUCTS,
-- 	  product_man_region) z danymi o regionach w których produkty powstały
--    (PRODUCT_MANUFACTURED_REGION, id).
--    W wynikach wyświetl wszystkie atrybuty z tabeli produktów i atrybut REGION_NAME
--    z tabeli PRODUCT_MANUFACTURED_REGION.
--    Dodatkowo wyfiltruj dane wynikowe taki sposób, aby pokazać tylko te produkty, dla
--    których regiony, w których powstały zostały założone po 2012 roku.
--    Porównaj te wyniki z wynikami z zadania 2.

     WITH regions_after_2012 AS 
		  (
		  SELECT pmr.region_name,
		         pmr.established_year
	   	    FROM product_manufactured_region pmr
 	       WHERE pmr.established_year > 2012
 	      )
   SELECT p.*,
	      pmr2.region_name
     FROM products p
LEFT JOIN product_manufactured_region pmr2 ON p.product_man_region = pmr2.id;

-- poprawione zapytanie:

   SELECT *
     FROM products p
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
    WHERE pmr.established_year > 2012; 
   
-- różnice pomiędzy zapytaniem z zad. 2: w podzapytaniu z zad. 2 dostajemy tabelę, w której
-- w region_name znajdują się wartości nieokreślone - LEFT JOIN pozostawia wszystkie wiersze
-- z tabeli products. Użycie WHERE filtruje je, usuwając wartości nieokreślone i pozostawiając
-- tylko jeden region z established_year spełniającym zadany warunek.

-- 4. Korzystając z konstrukcji RIGHT JOIN połącz dane sprzedażowe (SALES, sal_prd_id) z
--    podzapytaniem, w których dla danych produktowych uwzględnij tylko te produkty
--    (PRODUCTS, id), których ilość jednostek jest większa od 5 (product_quantity).
--    W wynikach wyświetl unikatową nazwę produktu (product_name) oraz złączeniem
--    ROK_MIESIĄC z danych sprzedażowych - data sprzedaży.
--    Dane posortuj według pierwszej kolumny malejąco.

    SELECT p.product_name,
	       p.product_quantity,
	       EXTRACT(YEAR FROM s.sal_date) || '_' || EXTRACT(MONTH FROM s.sal_date) sale_month
      FROM products p
RIGHT JOIN sales s ON p.id = s.sal_prd_id
     WHERE p.product_quantity > 5
  ORDER BY 1 DESC;

-- poprawione zapytanie

    SELECT DISTINCT prd.product_name,
	       prd.product_quantity,
	       EXTRACT(YEAR FROM s.sal_date) || '_' || EXTRACT(MONTH FROM s.sal_date) sale_month
      FROM sales s
RIGHT JOIN (SELECT p.*
              FROM products p
             WHERE p.product_quantity > 5) prd ON s.sal_prd_id = prd.id
  ORDER BY 1 DESC;


-- 5. Dodaj nowy region do tabeli PRODUCT_MANUFACTURED_REGION. 
--    Następnie korzystając z konstrukcji FULL JOIN połącz dane o produktach
--    (PRODUCTS,product_man_region) z danymi o regionach produktów w których
--    zostały one stworzone (PRODUCT_MANUFACTURED_REGION, id)
--    Wyświetl w wynikach wszystkie atrybuty z obu tabel.

     WITH product_manufactured_region_new AS 
	      (
	      INSERT INTO product_manufactured_region (region_name, region_code, established_year)
		       VALUES ('Mars', 'MRS', 2077)
	        RETURNING *
	      )
   SELECT *
     FROM products p
FULL JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id;

-- poprawione zapytanie (BŁĄD: INSERT posiada więcej docelowych kolumn niż wyrażeń)
     WITH product_manufactured_region_new AS 
	      (
	      INSERT INTO product_manufactured_region (region_name, region_code, established_year)
		       SELECT ('Mars', 'MRS', 2077)
		       WHERE NOT EXISTS 
		                        (
		                        SELECT *
		                          FROM product_manufactured_region pmr2
		                         WHERE pmr2.region_name = 'Mars'
		                       )
	        RETURNING *
	      )
   SELECT *
     FROM products p
FULL JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id;
	

-- wykonując to zapytanie wiele razy, każde wykonanie dodaje nowy wiersz z tymi samymi danymi (region_name,
-- region_code, established_year) - jak tego uniknąć?

-- 6. Uzyskaj te same wyniki, co w zadaniu 5 dla stworzonego zapytania, tym razem nie
--    korzystaj ze składni FULL JOIN. Wykorzystaj INNER JOIN / LEFT / RIGHT JOIN lub
--    inne części SQL-a, które znasz :)

-- stworz kopie tabeli product_manufactured_region na potrzebę zadania
DROP TABLE IF EXISTS pmr_temp;

CREATE TABLE pmr_temp (
	id SERIAL,
	region_name VARCHAR(25),
	region_code VARCHAR(10),
	established_year INTEGER
);

-- przekopiuj wartości z tabeli product_manufactured_region i dodaj jeden wiersz z dodatkowym regionem
INSERT INTO pmr_temp (region_name, region_code, established_year)
     SELECT region_name, region_code, established_year FROM product_manufactured_region;
INSERT INTO pmr_temp (region_name, region_code, established_year)
     VALUES ('Mars', 'MRS', 2077);

SELECT * FROM pmr_temp;
SELECT * FROM product_manufactured_region;

-- kombinacja LEFT i RIGHT JOIN zamiast FULL JOIN
    SELECT p.id AS product_id,
           p.product_name,
   	       p.product_code,
           p.product_quantity,
           p.manufactured_date,
           p.product_man_region,
           p.added_by,
           p.created_date
      FROM products p 
 LEFT JOIN pmr_temp pmrt ON p.product_man_region = pmrt.id
     UNION
    SELECT p.id AS product_id,
	       p.product_name,
	       p.product_code,
	       p.product_quantity,
	       p.manufactured_date,
	       p.product_man_region,
	       p.added_by,
	       p.created_date
      FROM products p
RIGHT JOIN pmr_temp pmrt ON p.product_man_region = pmrt.id
  ORDER BY product_id;
 
-- to samo zapytanie w wersji z CTE
WITH prod_temp AS 
     (
	 SELECT p.id AS product_id,
            p.product_name,
   	        p.product_code,
            p.product_quantity,
            p.manufactured_date,
            p.product_man_region,
            p.added_by,
            p.created_date
       FROM products p
      ),
      pmr_nr AS 
      (
      INSERT INTO product_manufactured_region (region_name, region_code, established_year)
           VALUES ('Mars', 'MRS', 2077)
        RETURNING *
      )
    SELECT * 
      FROM prod_temp
 LEFT JOIN product_manufactured_region pmr ON prod_temp.product_man_region = pmr.id
     UNION
    SELECT * 
      FROM prod_temp
RIGHT JOIN product_manufactured_region pmr ON prod_temp.product_man_region = pmr.id
  ORDER BY product_id, id;
 
-- poprawione zapytanie
    SELECT p.*,
           pmr.*
      FROM products p
      JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
     UNION 
    SELECT p.*,
           pmr.*
      FROM products p
 LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
     WHERE pmr.id IS NULL
     UNION
    SELECT p.*,
	       pmr.*
      FROM products p
RIGHT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
     WHERE p.id IS NULL;



-- 7. Wykorzystaj konstrukcję WITH i zmień Twoje zapytanie z zadania 4 w taki sposób, aby
--    podzapytanie znalazło się w sekcji CTE (common table expression = WITH) zapytania.


      WITH prod_quantity_over_5 AS 
	       (
	       SELECT *
	         FROM products
	        WHERE product_quantity > 5 
	          AND product_name IS NOT NULL
	       )
    SELECT DISTINCT pq5.product_name,
	       EXTRACT(YEAR FROM s.sal_date) || '-' || EXTRACT(MONTH FROM s.sal_date) sal_year_month
      FROM sales s
RIGHT JOIN prod_quantity_over_5 pq5 ON s.sal_prd_id = pq5.id
  ORDER BY sal_year_month;

-- 8. Usuń wszystkie te produkty (PRODUCTS), które są przypisane do regionu EMEA i kodu
--    E_EMEA.
--    Skorzystaj z konstrukcji USING lub EXISTS.

 DELETE FROM products p
WHERE EXISTS (
		        SELECT *
			      FROM products p
                  JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
             )
   RETURNING *;
  
-- poprawione zapytanie
 DELETE FROM products p
WHERE EXISTS (
		        SELECT 1 -- 1 ponieważ nie pobieramy wówczas żadnych kolumn
			      FROM products p1
             LEFT JOIN product_manufactured_region pmr ON pmr.id = p1.product_man_region
             )
   RETURNING *;

-- 9. OPCJONALNE: Korzystając z konstrukcji WITH RECURSIVE stwórz ciąg Fibonacciego,
--    którego wyniki będą ograniczone do wartości poniżej 100.

WITH RECURSIVE fibonacci(i, j, k) AS 
	 (
	 SELECT 1, 0::numeric, 1::numeric
	  UNION
	 SELECT i + 1, k, k + j
	   FROM fibonacci
	  WHERE k + j < 100
	 )
SELECT k AS fibonacci_number
  FROM fibonacci;