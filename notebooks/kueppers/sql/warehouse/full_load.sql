-- 25.03.2025
-- ETL-Prozess mit vollständigem Load,
-- d.h. alle Tabellen im DWH werden gelöscht
-- und neu befüllt

-- alle Tabellen löschen
drop table if exists ds420kupe1234_dwh.fact_invoice_position;
drop table if exists ds420kupe1234_dwh.dim_product;
-- ...


-- 1. Dimension "Produkt"
-- 1.1 Dimensionstabelle definieren
create table ds420kupe1234_dwh.dim_product (
	product_id int,  -- Umbenennung von Attributen: bspw. primary key immer mit ID, alles klein geschrieben
	product_name text, -- text ist nicht ideal (sehr lang), lassen wir aber so. Eher in Quellsystem umstellen!
	category_name varchar(100),
	vendor_name varchar(100),
	primary key (product_id)
);

-- 1.2 Daten in neue Tabelle laden 
-- 		(Reihenfolge der Attribute muss Tabellenstruktur entsprechen)
insert into ds420kupe1234_dwh.dim_product 
select p.`Product Number`, p.`Product Description`, 
		c.`Category Name`, v.`Vendor Name` 
from ils_small.product p
left join ils_small.category c on p.Category = c.Category 
left join ils_small.vendor v on p.`Vendor Number` = v.`Vendor Number`
;

-- 2. Fakten "Invoice_position" 
-- 2.1 Faktentabelle definieren
create table ds420kupe1234_dwh.fact_invoice_position (
	invoice_id varchar(40),
	position_id varchar(100),
	product_id int,
	order_volume_pcs int,
	turnover double,
	order_date date,
	store_id int,
	foreign key (product_id) references dim_product(product_id),
	primary key (invoice_id, position_id)
);

-- 2.2 Daten laden
insert into ds420kupe1234_dwh.fact_invoice_position
select ip.invoice_no, ip.item_no, ip.`Product Number`, 
		ip.`Bottles Sold`, ip.`Sale (Dollars)`,
		i.`Date`, i.`Store Number` 
from ils_small.invoice_position ip
inner join ils_small.invoice i on ip.invoice_no = i.invoice_no
;


-- 01.04.2025
-- Erweiterung des DWH-Datenmodells + ETL-Loads um 
-- Fakt "invoice" und Dimension "store"

-- Dimension Store
-- 3.1 Dimensionstabelle definieren
drop table if exists ds420kupe1234_dwh.dim_store;

create table ds420kupe1234_dwh.dim_store (
	store_id int primary key,  -- hier könnten wir auto_increment verwenden und rein DWH-interne IDs vergeben
	name varchar(100),
	address text,
	location varchar(100),
	zipcode int,
	-- city_id int,  -- nicht nötig, da interne IDs aus den Quelltabellen oftmals nicht gewünscht
	city varchar(100),
	county varchar(100)	
);

-- 3.2 Daten in dim_store laden 
-- 		(Reihenfolge der Attribute muss Tabellenstruktur entsprechen)
insert into ds420kupe1234_dwh.dim_store
select s.`Store Number`, s.`Store Name`, s.Address, s.`Store Location`,
		s.`Zip Code`, c.City, co.County 
from ils_small.store s
left join ils_small.city c on s.`City Number`= c.`City Number`
left join ils_small.county co on c.`County Number` = co.`County Number`
;

-- Fact Invoice
-- 4.1 Definition der Faktentabelle
drop table ds420kupe1234_dwh.fact_invoice;

create table ds420kupe1234_dwh.fact_invoice (
	invoice_id varchar(40) primary key,
	invoice_date date,
	store_id int,
	foreign key (store_id) references ds420kupe1234_dwh.dim_store (store_id)
);

-- 4.2 Laden der Daten
insert into ds420kupe1234_dwh.fact_invoice
select i.invoice_no, i.`Date`, i.`Store Number`  
from ils_small.invoice i
;


-- 5.1 Überarbeitung der Invoice-Position-Tabelle (Referenz auf Invoice)
drop table ds420kupe1234_dwh.fact_invoice_position;
create table ds420kupe1234_dwh.fact_invoice_position (
	invoice_id varchar(40),
	foreign key (invoice_id) references ds420kupe1234_dwh.fact_invoice(invoice_id),
	position_id varchar(100),
	product_id int,
	order_volume_pcs int,
	turnover double,
	order_date date,
	store_id int,
	foreign key (product_id) references dim_product(product_id),
	primary key (invoice_id, position_id)
);

-- Laden läuft identisch zu oben (den Code unter 2.2 nochmal ausführen)

-- Umsatz je County und Prod﻿ukt, absteigend nach Umsatz sortiert
select ds.county, dp.product_name, round(sum(fip.turnover), 2) as total_turnover
from ds420kupe1234_dwh.fact_invoice_position fip 
inner join ds420kupe1234_dwh.dim_product dp on fip.product_id = dp.product_id
inner join ds420kupe1234_dwh.fact_invoice fi on fip.invoice_id = fi.invoice_id
inner join ds420kupe1234_dwh.dim_store ds on fi.store_id = ds.store_id
group by ds.county, dp.product_name
order by total_turnover desc;

-- auch Produkte/Counties anzeigen ohne Umsatz  - haben wir aber nicht in den Daten
select ds.county, dp.product_name, round(sum(fip.turnover), 2) as total_turnover
from ds420kupe1234_dwh.fact_invoice_position fip 
right join ds420kupe1234_dwh.dim_product dp on fip.product_id = dp.product_id
left join ds420kupe1234_dwh.fact_invoice fi on fip.invoice_id = fi.invoice_id
right join ds420kupe1234_dwh.dim_store ds on fi.store_id = ds.store_id
group by ds.county, dp.product_name 
order by total_turnover desc;

-- Dimension Date

-- 5.1 Tabellenstruktur anlegen
CREATE TABLE ds420kupe1234_dwh.dim_date (
    `date` DATE PRIMARY KEY,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(15),
    week INT,
    weekday INT,
    weekday_name VARCHAR(15),
    is_weekend BOOLEAN
);

select min(invoice_date), max(invoice_date) from fact_invoice;

-- Benutzerdefinierte Variablen setzen
SET @start_date = '2000-01-01';
SET @end_date = '2024-04-30';
SET cte_max_recursion_depth = 10000;

-- Temporäre Zählhilfe: Liste mit Tagen)
insert into ds420kupe1234_dwh.dim_date (`date`, year, quarter, month, month_name, week, weekday, weekday_name, is_weekend)
WITH RECURSIVE datum_liste AS (
  SELECT @start_date AS datum
  UNION ALL
  SELECT DATE_ADD(datum, INTERVAL 1 DAY)
  FROM datum_liste
  WHERE datum < @end_date
)
SELECT
    datum,
    YEAR(datum) AS jahr,
    QUARTER(datum) AS quartal,
    MONTH(datum) AS monat,
    MONTHNAME(datum) AS monat_name,
    WEEK(datum, 3) AS woche,
    WEEKDAY(datum) + 1 AS wochentag,
    DAYNAME(datum) AS wochentag_name,
    CASE WHEN WEEKDAY(datum) IN (5,6) THEN TRUE ELSE FALSE END AS ist_wochenende
FROM datum_liste;


-- 4.1 Aktualisierung der Faktentabelle invoice
drop table ds420kupe1234_dwh.fact_invoice_position;
drop table ds420kupe1234_dwh.fact_invoice;

create table ds420kupe1234_dwh.fact_invoice (
	invoice_id varchar(40) primary key,
	invoice_date date,
	foreign key (invoice_date) references ds420kupe1234_dwh.dim_date(`date`),
	store_id int,
	foreign key (store_id) references ds420kupe1234_dwh.dim_store (store_id)
);

-- 4.2 ausführen (Daten erneut laden)
-- 5.1 und 5.2 ausführen (invoice position anlegen und laden)

-- Anzahl invoices pro Jahr/Quartal
select dd.year, dd.quarter, count(fi.invoice_id) as number_of_invoices
from ds420kupe1234_dwh.dim_date dd 
left join ds420kupe1234_dwh.fact_invoice fi on dd.`date` = fi.invoice_date
group by dd.year, dd.quarter
order by dd.year, dd.quarter
