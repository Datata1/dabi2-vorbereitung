
-- 15.04.2025
-- ETL-Prozess mit Delta Load,
-- d.h. alle Tabellen im DWH werden beibehalten und ... ?
drop table if exists dim_product;
create table ds420kupe1234_dwh.dim_product (
	product_id int,  -- Umbenennung von Attributen: bspw. primary key immer mit ID, alles klein geschrieben
	product_name text, -- text ist nicht ideal (sehr lang), lassen wir aber so. Eher in Quellsystem umstellen!
	category_name varchar(100),
	vendor_name varchar(100),
	primary key (product_id)
);

-- Bisheriger "Full Load" (initial nötig)
delete from ds420kupe1234_dwh.dim_product;
insert into ds420kupe1234_dwh.dim_product 
select p.`Product Number`, p.`Product Description`, 
		c.`Category Name`, v.`Vendor Name` 
from ils_small.product p
left join ils_small.category c on p.Category = c.Category 
left join ils_small.vendor v on p.`Vendor Number` = v.`Vendor Number`
;

select * from ils_small.product;

-- Delta Load: Identifikation von zu ändernden Produkten
update ds420kupe1234_dwh.dim_product dwh_p, ils_small.product p 
set dwh_p.product_name = p.`Product Description`
where dwh_p.product_id  = p.`Product Number`  -- ACHTUNG: impliziter Join (nötig für Update-Statement)
and p.`Product Description` != dwh_p.product_name;  -- nur beispielhaft für product_name, man müsste eigentlich alle geladenen Attribute auf Änderungen prüfen
;
-- ACHTUNG: Hier haben wir keine Historisierung!
-- Und es fehlen folgende Anwendungsfälle:
-- 1. Neue Produkte (haben wir nicht identifiziert und ins DWH geladen)
-- diese Menge "inserten"
select * from ils_small.product p 
left join ds420kupe1234_dwh.dim_product dwh_p on p.`Product Number` = dwh_p.product_id 
where dwh_p.product_id is null;
-- 2. Gelöschte Produkte (haben wir nicht identifiziert und im DWH gelöscht)
-- diese Menge "deleten"
select * from ils_small.product p 
right join ds420kupe1234_dwh.dim_product dwh_p on p.`Product Number` = dwh_p.product_id 
where p.`Product Number` is null;


-- Slowly Changing Dimension (Type 2)
drop table if exists dim_product;
create table ds420kupe1234_dwh.dim_product (
	dim_product_id int primary key auto_increment, -- surrogate key (künstlicher Schlüssel nur für das DWH!)
	product_id int,  -- Umbenennung von Attributen: bspw. primary key immer mit ID, alles klein geschrieben
	product_name text, -- text ist nicht ideal (sehr lang), lassen wir aber so. Eher in Quellsystem umstellen!
	category_name varchar(100),
	vendor_name varchar(100),
	valid_from date,
	valid_to date
);

-- SCD2 Schritt 1 "Full Load" (initial nötig)
SET @today := subdate(CURRENT_DATE, 5);  -- "Simulation" mehrerer Loads
SET @yesterday := SUBDATE(@today, 1);
set @minimum_valid := '1900-1-1';
set @maximum_valid := '9999-12-31';

insert into ds420kupe1234_dwh.dim_product 
select NULL, -- den künstlichen Primärschlüssel (surrogate key) einfach nicht übergeben
		p.`Product Number`, p.`Product Description`, 
		c.`Category Name`, v.`Vendor Name`,
		@minimum_valid, @maximum_valid  -- maximal mögliche Gültigkeit beim initialen Load
from ils_small.product p
left join ils_small.category c on p.Category = c.Category 
left join ils_small.vendor v on p.`Vendor Number` = v.`Vendor Number`
;

-- SCD2 Schritt 2 "Identifikation von Änderungen"
select * from ds420kupe1234_dwh.dim_product dwh_p, ils_small.product p 
where dwh_p.product_id  = p.`Product Number`  -- ACHTUNG: impliziter Join (nötig für Update-Statement)
and p.`Product Description` != dwh_p.product_name;  -- nur beispielhaft für product_name, man müsste eigentlich alle geladenen Attribute auf Änderungen prüfen
;

-- SCD2 Schritt 2.1 Bei Änderung des Produktnamens eine neue Zeile einfügen
insert into ds420kupe1234_dwh.dim_product 
select NULL, p.`Product Number`, p.`Product Description`, 
			c.`Category Name`, v.`Vendor Name`,
			@today, @maximum_valid 
from ds420kupe1234_dwh.dim_product p_dwh
left join ils_small.product p on p_dwh.product_id = p.`Product Number` 
left join ils_small.category c on p.Category = c.Category 
left join ils_small.vendor v on p.`Vendor Number` = v.`Vendor Number`
where p_dwh.product_name != p.`Product Description`  -- DELTA
and p_dwh.valid_to = @maximum_valid;   -- nur aktuell gültige Produkte selektieren

-- SCD2 Schritt 2.2 Bei Änderung des Produktnamens das valid_to vom bisherigen Eintrag anpassen
update dim_product p_dwh, ils_small.product p
set p_dwh.valid_to = @yesterday  -- Gültigkeit auf "gestern" setzen 
where p_dwh.product_id = p.`Product Number` -- IMPLIZITER JOIN
and p_dwh.product_name != p.`Product Description` -- !!! DELTA
and p_dwh.valid_to = @maximum_valid -- nur aktuell gültige Produkte selektieren
and curdate() between valid_from and valid_to  -- bisher gültig

-- SCD2 Schritt 3: Neue Produkte identifizieren und Einfügen
insert into dim_product
select NULL, p.`Product Number`, p.`Product Description`, 
			c.`Category Name`, v.`Vendor Name`,
			@today, @maximum_valid
from ils_small.product p
left join dim_product p_dwh on p_dwh.product_id = p.`Product Number` 
left join ils_small.category c on p.Category = c.Category 
left join ils_small.vendor v on p.`Vendor Number` = v.`Vendor Number`
where p_dwh.product_id is NULL; -- die Produkte, die es im DWH (noch) nicht gibt

-- SCD2 Schritt 4: Gelöschte Produkte identifizieren und valid_to entsprechend setzen
UPDATE dim_product p_dwh
LEFT JOIN ils_small.product p ON p_dwh.product_id = p.`Product Number`
SET p_dwh.valid_to = @today
WHERE p.`Product Number` IS NULL
AND p_dwh.valid_to = @maximum_valid;


-- 29.04.2025  -- Erweiterung des Konzepts um ein Faktentabellen
select * from dim_product where product_id = 1;



-- Diese Fakten möchten wir in fact_invoice_position laden:
select i.invoice_no, i.`Date`, ip.item_no, ip.`Bottles Sold`, ip.`Product Number`
from ils_small.invoice_position ip
inner join ils_small.invoice i on ip.invoice_no = i.invoice_no
where ip.`Product Number` = 1;


-- Anlegen der fact_invoice_position
create table fact_invoice_position (
	invoice_no varchar(50),
	invoice_date Date,
	invoice_position varchar(10),
	bottles_sold int,
	dim_product_id int,
	foreign key (dim_product_id) references dim_product(dim_product_id)
);
-- Identifikation von Fakten zu einem Produkt (vereinfacht nur invoice_positions gejoined mit invoices)
-- Setzen von valid_from / valid_to, um den Namenswechsel eines Produkts abzubilden
insert into fact_invoice_position
select i.invoice_no, i.`Date`, ip.item_no, ip.`Bottles Sold`, 
		dp.dim_product_id -- dies hier ist zu ersetzen durch den surrogate key
from ils_small.invoice_position ip
inner join ils_small.invoice i on ip.invoice_no = i.invoice_no
left join dim_product dp on ip.`Product Number` = dp.product_id and 
								i.`Date` between dp.valid_from and dp.valid_to;
							
select * from fact_invoice_position;
