DROP TABLE IF EXISTS products;

CREATE TABLE products (
	id SERIAL,
	product_name VARCHAR(100),
	product_code VARCHAR(10),
	product_quantity NUMERIC(10,2),
	manufactured_date DATE,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);

INSERT INTO products (product_name, product_code, product_quantity, manufactured_date)
 	 SELECT 'Product '||floor(random() * 10 + 1)::int,
 			'PRD'||floor(random() * 10 + 1)::int,
 		 	random() * 10 + 1,
 	     	CAST((NOW() - (random() * (interval '90 days')))::timestamp AS date)
   	   FROM generate_series(1, 10) s(i);

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
	id SERIAL,
	sal_description TEXT,
	sal_date DATE,
	sal_value NUMERIC(10,2),
	sal_qty NUMERIC(10,2),
	sal_product_id INTEGER,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);

INSERT INTO sales (sal_description, sal_date, sal_value, sal_qty, sal_product_id)
     SELECT left(md5(i::text), 15),
			CAST((NOW() - (random() * (interval '60 days'))) AS DATE),
			random() * 100 + 1,
			floor(random() * 10 + 1)::int,
			floor(random() * 10)::int
	   FROM generate_series(1, 10000) s(i);
	   


-- 1. Wyświetl unikatowe daty stworzenia produktów (według atrybutu manufactured_date)

SELECT DISTINCT manufactured_date
		   FROM products;
		  
-- 2. Jak sprawdzisz czy 10 wstawionych produktów to 10 unikatowych kodów produktów?

 SELECT DISTINCT ON (product_code) 
		 product_name, 
		 product_code
    FROM products
ORDER BY product_code;
-- mamy 6 wierszy zamiast 10, a więc kody produktów nie są unikatowe.
-- Da się to zrobić też bardziej bezpośrednio:

SELECT count(*)
FROM (SELECT DISTINCT ON (product_code) product_code
				    FROM products) AS unique_product_codes;
				   
				    
-- 3. Korzystając ze składni IN wyświetl produkty od kodach PRD1 i PRD9

SELECT *
  FROM products
 WHERE product_code IN ('PRD1', 'PRD9');

-- 4. Wyświetl wszystkie atrybuty z danych sprzedażowych, takie że data sprzedaży jest w
--    zakresie od 1 sierpnia 2020 do 31 sierpnia 2020 (włącznie). Dane wynikowe mają być
--    posortowane według wartości sprzedaży malejąco i daty sprzedaży rosnąco.


-- chyba robię to zadanie znacznie później, niż było przewidziane,
-- bo wszystkie daty w tabeli rozpoczynają się u mnie od września :)
-- dlatego zapytanie wykonałem dla października
  SELECT *
    FROM products
   WHERE manufactured_date BETWEEN '2020-10-01' AND '2020-10-30'
ORDER BY product_quantity DESC, 
		 manufactured_date ASC;
		 
-- 5. Korzystając ze składni NOT EXISTS wyświetl te produkty z tabeli PRODUCTS, które nie
--    biorą udziału w transakcjach sprzedażowych (tabela SALES). ID z tabeli Products i
--    SAL_PRODUCT_ID to klucz łączenia.

SELECT *
  FROM products p
 WHERE NOT EXISTS (SELECT 1
			  	     FROM sales s
			        WHERE p.id = s.sal_product_id);

-- 6. Korzystając ze składni ANY i operatora = wyświetl te produkty, których występują w
--    transakcjach sprzedażowych (według klucza Products ID, Sales SAL_PRODUCT_ID)
--    takich, że wartość sprzedaży w transakcji jest większa od 100.
			     
SELECT *
  FROM products p
 WHERE p.id = ANY(SELECT sal_product_id
				    FROM sales
				   WHERE sal_value > 100);
			     
SELECT sal_product_id
  FROM sales
 WHERE sal_value > 100;

-- 7. Stwórz nową tabelę PRODUCTS_OLD_WAREHOUSE o takich samych kolumnach jak
--	  istniejąca tabela produktów (tabela PRODUCTS). Wstaw do nowej tabeli kilka wierszy -
--	  dowolnych według Twojego uznania.

DROP TABLE IF EXISTS products_old_warehouse;

CREATE TABLE products_old_warehouse (
	id SERIAL,
	product_name VARCHAR(100),
	product_code VARCHAR(10),
	product_quantity NUMERIC(10,2),
	manufactured_date DATE,
	added_by TEXT DEFAULT 'admin',
	created_date TIMESTAMP DEFAULT now()
);


INSERT INTO products_old_warehouse (product_name, product_code, product_quantity, manufactured_date)
 	 SELECT 'Product '||floor(random() * 10 + 1)::int,
 			'PRD'||floor(random() * 10 + 1)::int,
 		 	random() * 10 + 1,
 	     	CAST(CAST('2018-09-01' AS date) + (random() * INTERVAL '90 days') AS date) 
 	     	-- czy da się powyższe wyrażenie zapisać prościej?
 	     	-- celem było wygenerowanie dat z zakresu 2018-09-01 <-> 2018-12-01
   	   FROM generate_series(1, 15) s(i);

SELECT *
  FROM products_old_warehouse;


-- 8. Na podstawie tabeli z zadania 7, korzystając z operacji UNION oraz UNION ALL połącz
--	  tabelę PRODUCTS_OLD_WAREHOUSE z 5 dowolnym produktami z tabeli
-- 	  PRODUCTS, w wyniku wyświetl jedynie nazwę produktu (kolumna PRODUCT_NAME)
--	  i kod produktu (kolumna PRODUCT_CODE). Czy w przypadku wykorzystania UNION
--	  jakieś wierszy zostały pominięte?

-- UNION
  SELECT product_name, product_code
    FROM products_old_warehouse
UNION
  (SELECT product_name, product_code 
    FROM products
    LIMIT 5);

-- Zamiast 20 rekordów otrzymujemy 18, a więc dwa z nich zostały pominięte.  
   
-- UNION ALL
  SELECT product_name, product_code
    FROM products_old_warehouse
UNION ALL
  (SELECT product_name, product_code
    FROM products
   LIMIT 5);  

   
-- 9. Na podstawie tabeli z zadania 7, korzystając z operacji EXCEPT znajdź różnicę zbiorów
--	  pomiędzy tabelą PRODUCTS_OLD_WAREHOUSE a PRODUCTS, w wyniku wyświetl
--	  jedynie kod produktu (kolumna PRODUCT_CODE).

  SELECT product_code
    FROM products_old_warehouse
  EXCEPT
  SELECT product_code
    FROM products
ORDER BY product_code;

-- 10. Wyświetl 10 rekordów z tabeli sprzedażowej sales. Dane powinny być posortowane
--	   według wartości sprzedaży (kolumn SAL_VALUE) malejąco.

  SELECT *
    FROM sales
ORDER BY sal_value DESC;

-- 11. Korzystając z funkcji SUBSTRING na atrybucie SAL_DESCRIPTION, wyświetl 3 dowolne
--	   wiersze z tabeli sprzedażowej w taki sposób, aby w kolumnie wynikowej dla
--	   SUBSTRING z SAL_DESCRIPTION wyświetlonych zostało tylko 3 pierwsze znaki.

SELECT 
		id,
		SUBSTRING(sal_description, 1, 3) sal_desc_substr,
		sal_date,
		sal_qty,
		sal_product_id,
		added_by,
		created_date
  FROM 	sales
 LIMIT 	3;

-- 12. Korzystając ze składni LIKE znajdź wszystkie dane sprzedażowe, których opis sprzedaży
--     (SAL_DESCRIPTION) zaczyna się od c4c.

SELECT *
  FROM sales
 WHERE sal_description LIKE 'c4c%';