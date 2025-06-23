drop table if exists fact_invoice_position;
create table fact_invoice_position (
	invoice_id varchar(40),
	position_id varchar(100),
	product_id int,
	order_volume_pcs int,
	turnover double,
	order_date date,
	store_id int,
	foreign key (product_id) references dim_product(dim_product_id),
	primary key (invoice_id, position_id)
);

drop table if exists fact_invoice;
create table fact_invoice (
	invoice_id varchar(40) primary key,
	invoice_date date,
	store_id int,
	foreign key (store_id) references dim_store (dim_store_id)
);