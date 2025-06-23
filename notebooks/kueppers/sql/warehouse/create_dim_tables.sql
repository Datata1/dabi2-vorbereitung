drop table if exists dim_product;

create table dim_product (
    dim_product_id int primary key auto_increment, -- surrogate key (künstlicher Schlüssel nur für das DWH!)
	product_id int,  -- Umbenennung von Attributen: bspw. primary key immer mit ID, alles klein geschrieben
	product_name text, -- text ist nicht ideal (sehr lang), lassen wir aber so. Eher in Quellsystem umstellen!
	category_name varchar(100),
	vendor_name varchar(100),
    valid_from date,
	valid_to date
);

drop table if exists dim_store;
create table dim_store (
    dim_store_id int primary key auto_increment,
	store_id int,  -- hier könnten wir auto_increment verwenden und rein DWH-interne IDs vergeben
	name varchar(100),
	address text,
	location varchar(100),
	zipcode int,
	-- city_id int,  -- nicht nötig, da interne IDs aus den Quelltabellen oftmals nicht gewünscht
	city varchar(100),
	county varchar(100),
    valid_from date,
	valid_to date	
);

