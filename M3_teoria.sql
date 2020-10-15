-- 1. Utw�rz nowy schemat o nazwie training

CREATE SCHEMA training;

-- 2. Zmie� nazw� schematu na training_zs;

ALTER SCHEMA training RENAME TO training_zs;

-- 3. Korzystaj�c z konstrukcji <nazwa_schematy>.<nazwa_tabeli> lub ��cz�c si� do schematu
--    training_zs, utw�rz tabel� wed�ug opisu.

CREATE TABLE training_zs.manufacturing_date (
	id INTEGER,
	production_qty NUMERIC(10, 2),
	product_name VARCHAR(100),
	product_code CHAR(10),
	description TEXT,
	manufacturing DATE
);

-- 4. Korzystaj�c ze sk�adni ALTER TABLE, dodaj klucz g��wny do tabeli products dla pola ID.

ALTER TABLE training_zs.products ADD PRIMARY KEY (id);
--ALTER TABLE training_zs.products ADD CONSTRAINT pk_customers PRIMARY KEY (id);

-- 5. Korzystaj�c ze sk�adni IF EXISTS spr�buj usun�� tabel� sales ze schematu training_zs

DROP TABLE IF EXISTS training_zs.sales;

-- 6. W schemacie training_zs, utw�rz now� tabel� sales wed�ug opisu.

CREATE TABLE training_zs.sales (
	id INTEGER PRIMARY KEY,
	sales_date TIMESTAMP NOT NULL,
	sales_amount NUMERIC(38, 2),
	sales_qty numeric(10, 2),
	product_id integer,
	added_by TEXT DEFAULT 'admin',
	CONSTRAINT sales_over_1k CHECK (sales_amount > 1000)
);

-- 7. Korzystaj�c z operacji ALTER utw�rz powi�zanie mi�dzy tabel� sales a products, jako klucz obcy
-- pomi�dzy atrybutami product_id z tabeli sales i id z tabeli products

ALTER TABLE training_zs.sales ADD CONSTRAINT product_id_fk FOREIGN KEY (product_id) REFERENCES training_zs.products (id) ON DELETE CASCADE;

-- 8. Korzystaj�c z polecenia DROP i opcji CASCADE usu� schemat training_zs

DROP SCHEMA training_zs CASCADE;

