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

-- 4. Wyświetl sumę sprzedaży na podstawie danych sprzedażowych (SALES) w podziale na
--    nowy atrybut ROK_MIESIAC stworzony na podstawie kolumny SAL_DATE. Dane
--    wynikowe posortuj od największej do najmniejszej sprzedaży.

-- 5. Korzystając z konstrukcji GROUPING SETS oblicz średnią ilość jednostek produktów w
--    grupach - kod produktu (PRODUCT_CODE), rok produkcji (na podstawie atrybutu
--    MANUFACTURED_DATE) oraz regionu produkcji (REGION_NAME z tabeli
--    PRODUCT_MANUFACTURED_REGION). Do danych wynikowych dołóż kolumnę z
--    grupą rekordów korzystając ze składni GROUPING.

-- 6. Dla każdego PRODUCT_NAME oblicz sumę ilości jednostek w podziale na region_name
--    z tabeli PRODUCT_MANUFACTURED_REGION. Skorzystaj z funkcji okna.
--    W wynikach wyświetl: PRODUCT_NAME, PRODUCT_CODE,
--    MANUFACTURED_DATE, PRODUCT_MAN_REGION, REGION_NAME i obliczoną
--    sumę.

-- 7. Na podstawie zapytania i wyników z zadania 6. Stwórz ranking według posiadanej ilości
--    produktów od największej do najmniejszej, w taki sposób, aby w rankingu nie było
--    brakujących elementów (liczb). W wyniku wyświetl te produkty, których ilość jest 2
--    największą ilością. Atrybuty do wyświetlenia, PRODUCT_NAME, REGION_NAME,
--suma ilości per region (obliczona w zadaniu 6)