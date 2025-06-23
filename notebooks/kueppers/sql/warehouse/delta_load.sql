-- SCD2 Schritt 1 "Full Load" (initial nötig)
SET @today := subdate(CURRENT_DATE, 5);  -- "Simulation" mehrerer Loads
SET @yesterday := SUBDATE(@today, 1);
set @minimum_valid := '1900-1-1';
set @maximum_valid := '9999-12-31';

insert into dim_product 
select NULL, -- den künstlichen Primärschlüssel (surrogate key) einfach nicht übergeben
		p.`Product Number`, p.`Product Description`, 
		c.`Category Name`, v.`Vendor Name`,
		@minimum_valid, @maximum_valid  -- maximal mögliche Gültigkeit beim initialen Load
from ds420wija1025_stg.product p
left join ds420wija1025_stg.category c on p.Category = c.Category 
left join ds420wija1025_stg.vendor v on p.`Vendor Number` = v.`Vendor Number`
;

-- SCD2 Schritt 2 "Identifikation von Änderungen"
select * from dim_product dwh_p, ds420wija1025_stg.product p 
where dwh_p.product_id  = p.`Product Number`  -- ACHTUNG: impliziter Join (nötig für Update-Statement)
and p.`Product Description` != dwh_p.product_name;  -- nur beispielhaft für product_name, man müsste eigentlich alle geladenen Attribute auf Änderungen prüfen
;

-- SCD2 Schritt 2.1 Bei Änderung des Produktnamens eine neue Zeile einfügen
insert into dim_product 
select NULL, p.`Product Number`, p.`Product Description`, 
			c.`Category Name`, v.`Vendor Name`,
			@today, @maximum_valid 
from dim_product p_dwh
left join ds420wija1025_stg.product p on p_dwh.product_id = p.`Product Number` 
left join ds420wija1025_stg.category c on p.Category = c.Category 
left join ds420wija1025_stg.vendor v on p.`Vendor Number` = v.`Vendor Number`
where p_dwh.product_name != p.`Product Description`  -- DELTA
and p_dwh.valid_to = @maximum_valid;   -- nur aktuell gültige Produkte selektieren

-- SCD2 Schritt 2.2 Bei Änderung des Produktnamens das valid_to vom bisherigen Eintrag anpassen
update dim_product p_dwh, ds420wija1025_stg.product p
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
from ds420wija1025_stg.product p
left join dim_product p_dwh on p_dwh.product_id = p.`Product Number` 
left join ds420wija1025_stg.category c on p.Category = c.Category 
left join ds420wija1025_stg.vendor v on p.`Vendor Number` = v.`Vendor Number`
where p_dwh.product_id is NULL; -- die Produkte, die es im DWH (noch) nicht gibt

-- SCD2 Schritt 4: Gelöschte Produkte identifizieren und valid_to entsprechend setzen
UPDATE dim_product p_dwh
LEFT JOIN ds420wija1025_stg.product p ON p_dwh.product_id = p.`Product Number`
SET p_dwh.valid_to = @today
WHERE p.`Product Number` IS NULL
AND p_dwh.valid_to = @maximum_valid;