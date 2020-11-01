-- 1. Utwórz nowy schemat dml_exercises

CREATE SCHEMA IF NOT EXISTS dml_exercises;

-- 2. Utwórz nową tabelę sales w schemacie dml_exercises 

DROP TABLE IF EXISTS dml_exercises.sales;

CREATE TABLE IF NOT EXISTS dml_exercises.sales (
	id serial PRIMARY KEY,
	sales_date timestamp NOT NULL,
	sales_amount numeric(38, 2),
	sales_qty numeric(10, 2),
	added_by text DEFAULT 'admin',
	CONSTRAINT sales_less_1k CHECK (sales_amount < 1000)
);

-- 3. Dodaj to tabeli kilka wierszy korzystając ze składni INSERT INTO
--- 3.1 Tak, aby id było generowane przez sekwencję
--- 3.2 Tak by pod pole added_by wpisać wartość nieokreśloną NULL
--- 3.3 Tak, aby sprawdzić zachowanie ograniczenia sales_less_1k, gdy wpiszemy wartości większe od 1000

INSERT INTO dml_exercises.sales (sales_date, sales_amount, sales_qty, added_by)
     VALUES ('27/10/2020', 600, 30, 'salesman_1'),
     		('28/10/2020', 880, 44, NULL),
     		('29/10/2020', 999, 10, 'salesman_3');
     	
INSERT INTO dml_exercises.sales (sales_date, sales_amount, sales_qty, added_by)
 	 VALUES ('30/10/2020', 1001, 10, 'salesman_1'); -- rekord narusza ograniczenie sprawdzające 

-- 4. Co zostanie wstawione, jako format godzina (HH), minuta (MM), sekunda (SS), w polu
--    sales_date, jak wstawimy do tabeli następujący rekord.
 
INSERT INTO dml_exercises.sales (sales_date, sales_amount,sales_qty, added_by)
     VALUES ('20/11/2019', 101, 50, NULL);

SELECT sales_date FROM dml_exercises.sales
 WHERE sales_amount = 101 
   AND sales_qty = 50;
--- format: 2019-11-20 00:00:00



-- 5. Jaka będzie wartość w atrybucie sales_date, po wstawieniu wiersza jak poniżej. Jak
--    zintepretujesz miesiąc i dzień, żeby mieć pewność, o jaki konkretnie chodzi.

INSERT INTO dml_exercises.sales (sales_date, sales_amount,sales_qty, added_by)
     VALUES ('04/04/2020', 101, 50, NULL);
     -- 2020-04-04 00:00:00.
     
     -- Sprawdzenie formatu daty:
     
     --- opcja 1
     
SHOW datestyle;

	 --- opcja 2
	 
SELECT TO_CHAR('04/04/2020' :: DATE, 'Mon dd, yyyy');


-- 6. Dodaj do tabeli sales wstaw wiersze korzystając z poniższego polecenia

INSERT INTO dml_exercises.sales (sales_date, sales_amount, sales_qty,added_by)
     SELECT NOW() + (random() * (interval '90 days')) + '30 days',
            random() * 500 + 1,
            random() * 100 + 1,
            NULL
       FROM generate_series(1, 20000) s(i);


-- 7. Korzystając ze składni UPDATE, zaktualizuj atrybut added_by, wpisując mu wartość
--    'sales_over_200', gdy wartość sprzedaży (sales_amount jest większa lub równa 200)

SELECT * FROM dml_exercises.sales  
   
UPDATE dml_exercises.sales
   SET added_by = 'sales_over_200'
 WHERE sales_amount >= 200;

-- 8. Korzystając ze składni DELETE, usuń te wiersze z tabeli sales, dla których wartość w polu
--    added_by jest wartością nieokreśloną NULL. Sprawdź różnicę między zapisemm added_by =
--    NULL, a added_by IS NULL

DELETE FROM dml_exercises.sales 
      WHERE added_by = NULL; 
--- updated rows: 0
--- wyjaśnienie: NULL nie jest wartością, dlatego nie operacja logiczna zwróci NULL (np. NULL = NULL zwraca NULL)

     
DELETE FROM dml_exercises.sales
      WHERE added_by IS NULL;
--- updated rows: 8019

     
-- 9. Wyczyść wszystkie dane z tabeli sales i zrestartuj sekwencje

TRUNCATE TABLE dml_exercises.sales RESTART IDENTITY;

-- 10. DODATKOWE ponownie wstaw do tabeli sales wiersze jak w zadaniu 4.
--     Utwórz kopię zapasową tabeli do pliku. Następnie usuń tabelę ze schematu dml_exercises i
--     odtwórz ją z kopii zapasowej