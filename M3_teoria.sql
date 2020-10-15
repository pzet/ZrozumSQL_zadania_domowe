-- 1. Utwórz nowy schemat o nazwie training

CREATE SCHEMA training;

-- 2. Zmieñ nazwê schematu na training_zs;

ALTER SCHEMA training RENAME TO training_zs;

-- 3. Korzystaj¹c z konstrukcji <nazwa_schematy>.<nazwa_tabeli> lub ³¹cz¹c siê do schematu
--    training_zs, utwórz tabelê wed³ug opisu.

CREATE TABLE training_zs.manufacturing_date (
	id INTEGER,
	production_qty NUMERIC(10, 2),
	product_name VARCHAR(100),
	product_code CHAR(10),
	description TEXT,
	manufacturing DATE
);

-- 4. Korzystaj¹c ze sk³adni ALTER TABLE, dodaj klucz g³ówny do tabeli products dla pola ID.

ALTER TABLE training_zs.products ADD PRIMARY KEY (id);
--ALTER TABLE training_zs.products ADD CONSTRAINT pk_customers PRIMARY KEY (id);

-- 5. Korzystaj¹c ze sk³adni IF EXISTS spróbuj usun¹æ tabelê sales ze schematu training_zs

DROP TABLE IF EXISTS training_zs.sales;

-- 6. W schemacie training_zs, utwórz now¹ tabelê sales wed³ug opisu.

CREATE TABLE training_zs.sales (
	id INTEGER PRIMARY KEY,
	sales_date TIMESTAMP NOT NULL,
	sales_amount NUMERIC(38, 2),
	sales_qty numeric(10, 2),
	product_id integer,
	added_by TEXT DEFAULT 'admin',
	CONSTRAINT sales_over_1k CHECK (sales_amount > 1000)
);

-- 7. Korzystaj¹c z operacji ALTER utwórz powi¹zanie miêdzy tabel¹ sales a products, jako klucz obcy
-- pomiêdzy atrybutami product_id z tabeli sales i id z tabeli products

ALTER TABLE training_zs.sales ADD CONSTRAINT product_id_fk FOREIGN KEY (product_id) REFERENCES training_zs.products (id) ON DELETE CASCADE;

-- 8. Korzystaj¹c z polecenia DROP i opcji CASCADE usuñ schemat training_zs

DROP SCHEMA training_zs CASCADE;

