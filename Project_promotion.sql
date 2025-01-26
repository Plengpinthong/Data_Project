select * from dim_campaigns
select * from dim_products
select * from dim_stores
select * from fact_events
use promotion
go

--1. List of a products with a base price greater than 500 and that are featured in promo type of 'BOGOF'
select
	d.product_name,
	d.category,
	f.base_price,
	f.promo_type,
	f.quantity_sold_before_promo,
	f.quantity_sold_after_promo
from fact_events f
join dim_products d on f.product_code = d.product_code
where base_price > 500 and promo_type = 'BOGOF'
go

--2. Calculate the difference in quantity and total price before and after the promotion was launched.
with promo as (
	select
		dc.campaign_name,
		dp.product_name,
		f.promo_type,
		f.base_price,
		sum(f.quantity_sold_before_promo) as 'quantity_before',
		sum(f.quantity_sold_after_promo) as 'quantity_after',
		case 
			when f.promo_type = '50% off' then cast(f.base_price as bigint)*sum(cast(quantity_sold_before_promo as bigint))
			when f.promo_type = 'BOGOF' then cast(f.base_price as bigint)*sum(cast(quantity_sold_before_promo as bigint))
			when f.promo_type = '25% off' then cast(f.base_price as bigint)*sum(cast(quantity_sold_before_promo as bigint))
			when f.promo_type = '33% off' then cast(f.base_price as bigint)*sum(cast(quantity_sold_before_promo as bigint)) 
			when f.promo_type = '500 cashback' then cast(f.base_price as bigint)*sum(cast(quantity_sold_before_promo as bigint))
		end as 'total_price_before_promo',
		case
			when f.promo_type = '50% off' then cast(f.base_price/2 as bigint)*sum(cast(quantity_sold_after_promo as bigint))
			when f.promo_type = 'BOGOF' then cast(f.base_price as bigint)*(sum(cast(quantity_sold_after_promo as bigint))/2)
			when f.promo_type = '25% off' then cast(f.base_price/4 as bigint)*sum(cast(quantity_sold_after_promo as bigint))
			when f.promo_type = '33% off' then cast(f.base_price*0.33 as bigint)*sum(cast(quantity_sold_after_promo as bigint)) 
			when f.promo_type = '500 cashback' then cast(f.base_price-500 as bigint)*sum(cast(quantity_sold_after_promo as bigint))
		end as 'total_price_after_promo'
	from fact_events f
	join dim_campaigns dc on dc.campaign_id = f.campaign_id
	join dim_products dp on dp.product_code = f.product_code
	group by dc.campaign_name, dp.product_name, f.promo_type, f.base_price
) 
select 
	*,
	(quantity_after - quantity_before) as 'quantity difference',
	(total_price_after_promo - total_price_before_promo) as 'total_price_difference'
from promo
order by campaign_name
go

--3. Which store has the highest quantity sold before/after campaigns?
	--Before campaigns
select
	store_id, 
	sum(quantity_sold_before_promo) as 'quantity_sold'
from fact_events
group by store_id
order by quantity_sold desc
	--After campaigns
select
	store_id, 
	sum(quantity_sold_after_promo) as 'quantity_sold'
from fact_events
group by store_id
order by quantity_sold desc
go

--4. Bestseller product before and after campaigns (by quantity)
	--Before campaigns
select 
	dp.product_code,
	dp.product_name,
	sum(quantity_sold_before_promo) as 'count_product_sold'
from fact_events f
join dim_products dp on dp.product_code = f.product_code 
group by dp.product_code, dp.product_name, f.base_price
order by count_product_sold desc
	--After campaigns
select 
	dp.product_code,
	dp.product_name,
	sum(quantity_sold_after_promo) as 'count_product_sold'
from fact_events f
join dim_products dp on dp.product_code = f.product_code 
group by dp.product_code, dp.product_name, f.base_price
order by count_product_sold desc
go 

--5. How many stores are there in each city?
select 
	city,
	count(store_id) as 'count_store'
from dim_stores
group by city
order by count_store desc

--6. Quantity sold in each city before/after the campaigns.
	--Before campaigns
select
	ds.city,
	count(distinct(ds.store_id)) as 'stores_number',
	sum(quantity_sold_before_promo) as 'sales_by_city'
from fact_events f
join dim_stores ds on ds.store_id = f.store_id
group by ds.city
order by sales_by_city desc
	--After campaigns
select
	ds.city,
	count(distinct(ds.store_id)) as 'stores_number',
	sum(quantity_sold_after_promo) as 'sales_by_city'
from fact_events f
join dim_stores ds on ds.store_id = f.store_id
group by ds.city
order by sales_by_city desc
go

--7. Incremental sold units and ISU% by promo_type
with promo as (
	select
		promo_type,
		sum(quantity_sold_before_promo) as 'quantity_before',
		sum(quantity_sold_after_promo) as 'quantity_after',
		sum(quantity_sold_after_promo) - sum(quantity_sold_before_promo) as 'incremental_sold_units'
	from fact_events 
	group by promo_type
) 
select 
	promo_type,
	incremental_sold_units,
	format((incremental_sold_units * 1.0 / quantity_before) * 100, 'N2') as 'ISU%'
from promo
order by promo_type
