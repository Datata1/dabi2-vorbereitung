-- =================================================================================
-- 01_create_star_schema.sql
-- =================================================================================
-- Zweck: Dieses Skript erstellt das komplette Star-Schema des Data Warehouse
--        und führt einen initialen "Full Load" der Daten aus den Quellsystemen durch.
--
-- Konzept: Ein Star-Schema besteht aus einer zentralen Faktentabelle, die
--          Kennzahlen enthält, und mehreren Dimensionstabellen, die die beschreibenden
--          Attribute (wer, was, wo, wann) enthalten.
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- SCHRITT 0: BEREINIGUNG (um das Skript wiederholbar zu machen)
-- ---------------------------------------------------------------------------------
-- Wir löschen die Tabellen in umgekehrter Reihenfolge ihrer Abhängigkeiten
-- (zuerst Fakten, dann Dimensionen).

DROP TABLE IF EXISTS dwh.fact_sales;
DROP TABLE IF EXISTS dwh.dim_product;
DROP TABLE IF EXISTS dwh.dim_store;
DROP TABLE IF EXISTS dwh.dim_date;

-- Erstellt die Schema/Datenbank, falls sie nicht existiert
CREATE SCHEMA IF NOT EXISTS dwh;


-- ---------------------------------------------------------------------------------
-- SCHRITT 1: DIMENSIONSTABELLEN ERSTELLEN UND BEFÜLLEN
-- ---------------------------------------------------------------------------------

-- 1.1 Dimension "Produkt"
-- Enthält alle beschreibenden Informationen über ein Produkt.
CREATE TABLE dwh.dim_product (
    product_id INT PRIMARY KEY,         -- Business Key aus dem Quellsystem
    product_name VARCHAR(255),
    category_name VARCHAR(100),
    vendor_name VARCHAR(100)
);

-- Befüllen der dim_product Tabelle
INSERT INTO dwh.dim_product (product_id, product_name, category_name, vendor_name)
SELECT
    p.`Product Number`,
    p.`Product Description`,
    c.`Category Name`,
    v.`Vendor Name`
FROM source.product p
LEFT JOIN source.category c ON p.Category = c.Category
LEFT JOIN source.vendor v ON p.`Vendor Number` = v.`Vendor Number`;


-- 1.2 Dimension "Store"
-- Enthält alle Informationen über einen Laden/Standort.
CREATE TABLE dwh.dim_store (
    store_id INT PRIMARY KEY,           -- Business Key
    store_name VARCHAR(100),
    address VARCHAR(255),
    zip_code VARCHAR(10),
    city VARCHAR(100),
    county VARCHAR(100)
);

-- Befüllen der dim_store Tabelle
INSERT INTO dwh.dim_store (store_id, store_name, address, zip_code, city, county)
SELECT
    s.`Store Number`,
    s.`Store Name`,
    s.Address,
    s.`Zip Code`,
    c.City,
    co.County
FROM source.store s
LEFT JOIN source.city c ON s.`City Number` = c.`City Number`
LEFT JOIN source.county co ON c.`County Number` = co.`County Number`;


-- 1.3 Dimension "Datum"
-- Enthält alle Datumsattribute. Sie wird oft einmalig erstellt und selten geändert.
CREATE TABLE dwh.dim_date (
    `date` DATE PRIMARY KEY,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(15),
    day_of_week_name VARCHAR(15)
);

-- Befüllen der dim_date Tabelle (hier vereinfacht mit Daten aus den Invoices)
INSERT INTO dwh.dim_date (`date`, year, quarter, month, month_name, day_of_week_name)
SELECT DISTINCT
    i.`Date` AS `date`,
    YEAR(i.`Date`) AS year,
    QUARTER(i.`Date`) AS quarter,
    MONTH(i.`Date`) AS month,
    MONTHNAME(i.`Date`) AS month_name,
    DAYNAME(i.`Date`) AS day_of_week_name
FROM source.invoice i
WHERE i.`Date` IS NOT NULL;


-- ---------------------------------------------------------------------------------
-- SCHRITT 2: FAKTENTABELLE ERSTELLEN UND BEFÜLLEN
-- ---------------------------------------------------------------------------------
-- Die Faktentabelle enthält die Kennzahlen (z.B. Umsatz, Menge) und die
-- Foreign Keys, die auf die Dimensionstabellen verweisen.

CREATE TABLE dwh.fact_sales (
    invoice_id VARCHAR(50),
    position_id INT,
    product_id INT,                 -- Foreign Key zu dim_product
    store_id INT,                   -- Foreign Key zu dim_store
    date DATE,                      -- Foreign Key zu dim_date
    quantity_sold INT,
    turnover_usd DECIMAL(12, 2),
    PRIMARY KEY (invoice_id, position_id), -- Zusammengesetzter Primärschlüssel
    FOREIGN KEY (product_id) REFERENCES dwh.dim_product(product_id),
    FOREIGN KEY (store_id) REFERENCES dwh.dim_store(store_id),
    FOREIGN KEY (date) REFERENCES dwh.dim_date(`date`)
);

-- Befüllen der fact_sales Tabelle
INSERT INTO dwh.fact_sales (invoice_id, position_id, product_id, store_id, date, quantity_sold, turnover_usd)
SELECT
    ip.invoice_no,
    ip.item_no,
    ip.`Product Number`,
    i.`Store Number`,
    i.`Date`,
    ip.`Bottles Sold`,
    ip.`Sale (Dollars)`
FROM source.invoice_position ip
INNER JOIN source.invoice i ON ip.invoice_no = i.invoice_no;

-- =================================================================================
-- INITIALER LOAD ABGESCHLOSSEN
-- =================================================================================
```
