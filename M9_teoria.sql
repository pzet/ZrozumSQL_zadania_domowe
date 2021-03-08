-- Przygotowanie - korzystając ze skryptu poniżej utwórz obiekty potrzebne do zadania.
-- https://github.com/morb1d/zrozumsql/blob/master/zs_exercises/M9_L13_SAMPLE_DATA_FOR_THEORY_EXERCISES.sql
-- W skryptach do sprawdzenia, nie podawaj proszę wartości wynikowych tylko samą składnię
-- z ewentualnym opisem.
--
--1. Przygotuj widok bazodanowy na podstawie danych sprzedażowych SALES, który będzie
--   przedstawiał dane za ostatni kwartał roku 2020, dla wszystkich produktów biorących
--   udział w transakcjach sprzedażowych wytworzonych w regionie EMEA.
--
-- 2. Zmień zapytanie z zadania pierwszego w taki sposób, aby w wynikach dodatkowo,
--    obliczyć sumę sprzedaży w podziale na kod produktu (product_code) sortowane według
--    daty sprzedaży (sal_date), wynik wyświetl dla każdego wiersza (OVER). Tak
--    przygotowane zapytanie wykorzystaj do stworzenia widoku zmaterializowanego, który
--    będzie mógł być odświeżany równolegle (CONCURRENTLY).

-- 3. Stwórz zapytanie, w którego wynikach znajdą się atrybuty: PRODUCT_CODE,
--    REGION_NAME i tablica zawierają nazwy produktów (PRODUCT_NAME) dla
--    wszystkich produktów z tabeli PRODUCTS.

-- 4. Dla zapytania z zdania 3 stwórz nową tabelę korzystając z konstrukcji CTAS. Dodaj
--    dodatkowo do nowej tabeli 1 kolumnę zawierającą wartość TRUE lub FALSE obliczaną
--    na podstawie danych z atrybutu tablicy nazw produktów dla kodu i regionu (zadanie 3)
--    w taki sposób, że gdy tablica zawiera więcej niż 1 element wartość ma być TRUE, w
--    przeciwnym razie FALSE.

-- 5. Stwórz nową tabelę SALES_ARCHIVE (jako zwykły CREATE TABLE nie CTAS), która
--    będzie miała strukturę na podstawie tabeli SALES z wyjątkami:
--    - nowy atrybut: operation_type VARCHAR(1) NOT NULL
--    - nowy atrybut: archived_at TIMESTAMP z automatycznym przypisywaniem
--      wartości NOW()
--    - atrybut created_date powinien być usunięty

-- 6. Dla tabeli stworzonej w zadaniu 5, utwórz TRIGGER + FUNKCJE DLA TRIGGERA, który
--    w momencie usuwania, lub aktualizacji wierszy w tabeli SALES, wstawi informację o
--    poprzedniej wartości do tabeli SALES_ARCHIVE. Po przypisaniu TRIGGERA, usuń z
--    tabeli SALES wszystkie dane sprzedażowe z Października 2020 (10.2020).