-- 1. Korzystając z tabel administracyjnych bazy danych. Stwórz zapytanie, którego
--    wynikiem będzie lista obiektów:
--    Tabel, widoków, indeksów, typem (t dla tabeli, v dla widoku, i dla indeksu) razem
--    z ich właścicielami i schematem, w jakim się znajdują.

   SELECT tablename AS object_name,
          schemaname,  
          tableowner AS object_owner,
          't' AS object_type
     FROM pg_tables
    UNION
   SELECT pi.indexname AS object_name,
          pi.schemaname,          
          pt.tableowner AS object_owner,
          'i' AS object_type
     FROM pg_indexes pi
LEFT JOIN pg_tables pt ON pt.tablename = pi.tablename
    UNION
   SELECT viewname AS object_name,
          schemaname,          
          viewowner AS object_owner,
          'v' AS object_type
     FROM pg_views
 ORDER BY object_name;
 
--2. Korzystając z dodatku pgcrypto (lub z odpowiadających funkcji w Twojej bazie
--   danych).
--   Zaszyfruj tekst 'ultraSilneHa3l0$567' korzystając z opcji ENCRYPT (pamiętaj o
--   rzutowaniu na typ bytea - ::bytea lub CAST(xxx as bytea)) or CRYPT
--   Następnie przedstaw sposób, sprawdzania hasła w sytuacji logowania
--   użytkownika (DECRYPT / CRYPT)


-- encrypt()
SELECT encrypt('ultraSilneHa3l0$567'::bytea, gen_salt('md5')::bytea, 'aes')

-- crypt()
CREATE EXTENSION pgcrypto;

SELECT crypt('ultraSilneHa3l0$567', gen_salt('md5'))

-- nowa tabela z haslami w zaszyfrowanej formie
CREATE TABLE expense_tracker.users_crypt
   AS SELECT * 
        FROM expense_tracker.users;

SELECT * FROM expense_tracker.users_crypt

-- dodanie do tabeli kolumny z zaszyfrowanymi haslami
ALTER TABLE expense_tracker.users_crypt
 ADD COLUMN user_password_crypt varchar(100);

UPDATE expense_tracker.users_crypt
   SET user_password_crypt = crypt(user_password, gen_salt('md5'));

-- tabela przechowujaca hasla niezaszyfrowane i zaszyfrowane
SELECT user_login, 
	   user_password, 
	   user_password_crypt 
  FROM expense_tracker.users_crypt;

-- sprawdzenie poprawnosci hasla:
SELECT user_login,
       user_password_crypt = crypt(user_password, user_password_crypt) AS correct_password
FROM expense_tracker.users_crypt;


-- 3. Dla danych z tabeli CUSTOMERS (skrypt poniżej), wykorzystaj znane Ci techniki
--    anonimizowania danych.
--    a. Pozbądź się duplikatów.
--    b. Nie pokazuj całego adresu email, tylko domenę firmy (np. X@polska.pl) -
--       dla znalezienie domeny mailowej możesz wykorzystać REGEX - '@(.*)$'
--       (w substring lub REGEXP_MATCH)
--    c. Pokaż tylko 3 ostatniej cyfry numeru telefonu (resztę zastąp X-ami).


DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
	id SERIAL,
	c_name TEXT,
	c_mail TEXT,
	c_phone VARCHAR(9),
	c_description TEXT
);

INSERT INTO customers (c_name, c_mail, c_phone, c_description)
     VALUES ('Krzysztof Bury', 'kbur@domein.pl', '123789456',
            left(md5(random()::text), 15)),
            ('Onufry Zagłoba', 'zagloba@ogniemimieczem.pl',
            '100000001', left(md5(random()::text), 15)),
            ('Krzysztof Bury', 'kbur@domein.pl', '123789456',
            left(md5(random()::text), 15)),
            ('Pan Wołodyjowski', 'p.wolodyj@polska.pl',
            '987654321', left(md5(random()::text), 15)),
            ('Michał Skrzetuski', 'michal<at>zamek.pl',
            '654987231', left(md5(random()::text), 15)),
            ('Bohun Tuhajbejowicz', NULL, NULL,
            left(md5(random()::text), 15));

SELECT * FROM customers;

-- a. usuwanie duplikatow
-- sprawdzamy czy duplikaty istnieja
  SELECT c_name, c_mail, c_phone, count(*) AS cnt
    FROM customers c
GROUP BY c_name, c_mail, c_phone
  HAVING count(*) > 1;

-- usun duplikat o nizszym id (jako mniej aktualny)
 DELETE 
  FROM customers c2 
  WHERE c2.id NOT IN (
	  SELECT max(c.id)
	    FROM customers c
	GROUP BY c_name, c_mail, c_phone
  );
  
  SELECT c_name, c_mail, c_phone, count(*) AS cnt
    FROM customers c
GROUP BY c_name, c_mail, c_phone
  HAVING count(*) > 1;
-- sprawdzenie: duplikat usuniety
 
--    b. Nie pokazuj całego adresu email, tylko domenę firmy (np. X@polska.pl) -
--       dla znalezienie domeny mailowej możesz wykorzystać REGEX - '@(.*)$'
--       (w substring lub REGEXP_MATCH)

SELECT *,
       CASE WHEN c_mail IS NULL THEN 'unknown'
       ELSE 'known' END
FROM customers;

SELECT c_mail,
	   CASE WHEN c_mail IS NOT NULL THEN regexp_match(c_mail, '(?<=(<at>|@)).*')
	   ELSE NULL END
  FROM customers
  
--    c. Pokaż tylko 3 ostatniej cyfry numeru telefonu (resztę zastąp X-ami).
SELECT c_phone,
       repeat('X', length(c_phone) - 3) || substring(c_phone, length(c_phone) - 2, length(c_phone))
  FROM customers;
  