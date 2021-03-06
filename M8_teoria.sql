-- 1. Oblicz średnią ilość jednostek produktów (PRODUCTS) w podziale na regiony z tabeli
--    PRODUCT_MANUFACTURED_REGION (atrybut region_name). W wynikach wyświetl
--    tylko nazwę regionu (REGION_NAME) i obliczoną średnią. Dane posortuj według
--    średniej malejąco.

   SELECT pmr.region_name,
          avg(p.product_quantity) avg_prod_quantity
     FROM products p
     JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
 GROUP BY pmr.region_name
 ORDER BY avg_prod_quantity DESC;

-- 2. Korzystając z funkcji STRING_AGG, dla każdej nazwy regionu z tabeli
--    PRODUCT_MANUFACTURED_REGION stwórz listę nazw produktów (product_name)
--    w tych regionach. Sprawdź czy wewnątrz funkcji STRING_AGG możesz użyć ORDER
--    BY i jak ewentualnie to wpłynie na wyniki?

   SELECT pmr.region_name,
          string_agg(product_code, ', ') product_code
     FROM products p
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region 
 GROUP BY pmr.region_name;

-- można użyć ORDER BY wewnątrz funkcji string_agg() - otrzymujemy alfabetyczną 
-- kolejność kodów produktów wewnątrz rekordu
   SELECT pmr.region_name,
          string_agg(product_code, ', ' ORDER BY product_code) product_code
     FROM products p
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region 
 GROUP BY pmr.region_name;

-- 3. Wyświetl ilość sprzedanych produktów COUNT(s.sal_prd_id), które wzięły udział w
--    transakcjach sprzedażowych, filtrując dane jedynie do regionu EMEA, według tabeli
--    PRODUCT_MANUFACTURED_REGION. W danych wynikowych powinien się znaleźć
--    region (REGION_NAME), nazwa produktu (PRODUCT_NAME) oraz całkowita liczba z
--    danych sprzedażowych.

 SELECT  pmr.region_name,
         p.product_name,
         count(s.sal_prd_id) product_sales
    FROM sales s
    JOIN products p ON p.id = s.sal_prd_id
    JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region 
	                                    AND pmr.region_name = 'EMEA'
GROUP BY pmr.region_name, p.product_name;


-- 4. Wyświetl sumę sprzedaży na podstawie danych sprzedażowych (SALES) w podziale na
--    nowy atrybut ROK_MIESIAC stworzony na podstawie kolumny SAL_DATE. Dane
--    wynikowe posortuj od największej do najmniejszej sprzedaży.

  SELECT EXTRACT(YEAR FROM s.sal_date) || '_' || EXTRACT(MONTH FROM s.sal_date) year_month,
         sum(s.sal_value) sum_of_sales
    FROM sales s
GROUP BY year_month
ORDER BY sum_of_sales DESC;

-- 5. Korzystając z konstrukcji GROUPING SETS oblicz średnią ilość jednostek produktów w
--    grupach - kod produktu (PRODUCT_CODE), rok produkcji (na podstawie atrybutu
--    MANUFACTURED_DATE) oraz regionu produkcji (REGION_NAME z tabeli
--    PRODUCT_MANUFACTURED_REGION). Do danych wynikowych dołóż kolumnę z
--    grupą rekordów korzystając ze składni GROUPING.


  SELECT p.product_code,
         EXTRACT(YEAR FROM p.manufactured_date) prod_year,
         pmr.region_name,
         GROUPING(p.product_code, 
                  EXTRACT(YEAR FROM p.manufactured_date), 
                  pmr.region_name),
         avg(p.product_quantity) avg_prod_quantity
    FROM products p
    JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id 
GROUP BY GROUPING SETS (p.product_code, EXTRACT(YEAR FROM p.manufactured_date), pmr.region_name);
-- dlaczego grupy są 3, 5, 6?
-- z dokumentacji do GROUPING - nie zwraca numeru, ale maskę bitów!
--W GROUPING mamy tutaj 3 atrybuty, więc potencjalnie także 3 bity
--0 - product_code, 0 - manufactured_date, 0 - region_name
--000 - 0
--001 - 1 (grupowanie tylko po region_name)
--010 - 2
--011 - 3
--100 - 4
--101 - 5
--110 - 6 (grupowanie po product_code i manufactured_date)
--111 - 7

-- dlaczego to podzapytanie (modyfikacja GROUPING SETS) zwraca zupełnie inny wynik?
  SELECT p.product_code,
         EXTRACT(YEAR FROM p.manufactured_date) prod_year,
         pmr.region_name,
         GROUPING(p.product_code, EXTRACT(YEAR FROM p.manufactured_date), 
                  pmr.region_name),
         avg(p.product_quantity) avg_prod_quantity
    FROM products p
    JOIN product_manufactured_region pmr ON p.product_man_region = pmr.id 
GROUP BY GROUPING SETS ((p.product_code, EXTRACT(YEAR FROM p.manufactured_date), pmr.region_name));
--obłożenie dodatkowymi nawiasami sprawia, że ostatni fragment traktowany jest jako jeden GROUPING
--z 3ech podgrup robi się jedna podgrupa - z GROUPING SET robi się zwykły GROUP BY

-- 6. Dla każdego PRODUCT_NAME oblicz sumę ilości jednostek w podziale na region_name
--    z tabeli PRODUCT_MANUFACTURED_REGION. Skorzystaj z funkcji okna.
--    W wynikach wyświetl: PRODUCT_NAME, PRODUCT_CODE,
--    MANUFACTURED_DATE, PRODUCT_MAN_REGION, REGION_NAME i obliczoną
--    sumę.

   SELECT p.product_name,
          p.product_code,
          p.manufactured_date,
          p.product_man_region,
          pmr.region_name,
          sum(p.product_quantity) OVER (PARTITION BY pmr.region_name)
     FROM products p
LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region;

-- 7. Na podstawie zapytania i wyników z zadania 6. Stwórz ranking według posiadanej ilości
--    produktów od największej do najmniejszej, w taki sposób, aby w rankingu nie było
--    brakujących elementów (liczb). W wyniku wyświetl te produkty, których ilość jest 2
--    największą ilością. Atrybuty do wyświetlenia, PRODUCT_NAME, REGION_NAME,
--    suma ilości per region (obliczona w zadaniu 6)

SELECT tt.*,
       dense_rank() OVER (ORDER BY tt.sum_prod DESC) prod_quant_rank
  FROM (   
           SELECT p.product_name,
                  pmr.region_name,
                  sum(p.product_quantity) OVER (PARTITION BY pmr.region_name) sum_prod
             FROM products p
        LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
       ) tt;
-- UWAGA! Aby użyć window function w WHERE, trzeba użyć CTE:

  WITH products_ranked AS (
	SELECT tt.*,
       	   dense_rank() OVER (ORDER BY tt.sum_prod DESC) prod_quant_rank
      FROM (   
           SELECT p.product_name,
                  pmr.region_name,
                  sum(p.product_quantity) OVER (PARTITION BY pmr.region_name) sum_prod
             FROM products p
        LEFT JOIN product_manufactured_region pmr ON pmr.id = p.product_man_region
	) tt
)
SELECT * 
  FROM products_ranked 
 WHERE prod_quant_rank = 2;
