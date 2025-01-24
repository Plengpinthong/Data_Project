--Total spend per customer for 6 months--
select 
	d.customer_id,
	d.occupation, sum(f.spend) as 'Total Spend'
from dim_customers d
join fact_spends f on f.customer_id = d.customer_id
group by d.customer_id, d.occupation
order by sum(f.spend) desc
GO

--Total spend by credit card per customer for 6 months--
select 
	d.customer_id, 
	sum(f.spend) as 'Credit card spend'
from dim_customers d
join fact_spends f on f.customer_id = d.customer_id
where f.payment_type = 'Credit card'
group by d.customer_id
order by sum(f.spend) desc
GO

--Total spend per categories for 6 month by credit card--
select 
	f.category, 
	sum(f.spend) 'Paid by Credit card'
from dim_customers d
join fact_spends f on f.customer_id = d.customer_id
where f.payment_type = 'Credit card'
group by f.category
order by sum(f.spend) desc
GO

--Gender per city--
select	
	city, 
	count(case when gender = 'Male' then 1 end) as 'Male',
	count(case when gender = 'Female' then 1 end) as 'Female'
from dim_customers
group by city;
Go

--Total Spend, Average Spend per month per customer--
select	
	d.customer_id, 
	d.avg_income, 
	sum(case when f.month = 'May' then f.spend else 0 end) as 'May',
	sum(case when f.month = 'June' then f.spend else 0 end) as 'June',
	sum(case when f.month = 'July' then f.spend else 0 end) as 'July',
	sum(case when f.month = 'August' then f.spend else 0 end) as 'August',
	sum(case when f.month = 'September' then f.spend else 0 end) as 'September',
	sum(case when f.month = 'October' then f.spend else 0 end) as 'October',
	sum(f.spend) as 'Total spend',
	sum(f.spend)/count(distinct(month)) 'Average spend Per month' 
from dim_customers d
join fact_spends f on f.customer_id = d.customer_id
group by d.customer_id, d.avg_income
order by d.customer_id asc

--Total and Average Spend per month--
select	
	month, 
	sum(spend) as 'Total Spend', 
	sum(spend)/4000 as 'Avg spend per customer'
from fact_spends
group by month

--count payment type per customer--
select  
	customer_id,
	count(case when payment_type = 'upi' then 1 end) as 'UPI',
	count(case when payment_type = 'credit card' then 1 end) as 'Credit card',
	count(case when payment_type = 'debit card' then 1 end) as 'Debit card',
	count(case when payment_type = 'net banking' then 1 end) as 'Net banking'
from fact_spends
group by customer_id
order by customer_id asc
GO

--Average spend per month by categories per customer--
select	
	month, 
	sum(case when category = 'Bills' then spend else 0 end)/count(distinct(customer_id)) as 'Bills',
	sum(case when category = 'Groceries' then spend else 0 end)/count(distinct(customer_id)) as 'Groceries',
	sum(case when category = 'Apparel' then spend else 0 end)/count(distinct(customer_id)) as 'Apparel',
	sum(case when category = 'entertainment' then spend else 0 end)/count(distinct(customer_id)) as 'entertainment',
	sum(case when category = 'others' then spend else 0 end)/count(distinct(customer_id)) as 'others',
	sum(case when category = 'food' then spend else 0 end)/count(distinct(customer_id)) as 'food',
	sum(case when category = 'health & wellness' then spend else 0 end)/count(distinct(customer_id)) as 'health & wellness',
	sum(case when category = 'electronics' then spend else 0 end)/count(distinct(customer_id)) as 'electronics',
	sum(case when category = 'travel' then spend else 0 end)/count(distinct(customer_id)) as 'travel'
from fact_spends 
group by month
order by bills desc
go

--Average Spend (per month) by occupation--
select 
	d.occupation, 
	(sum(f.spend)/count(distinct(f.customer_id)))/6 as 'Average spend'
from dim_customers d
join fact_spends f on f.customer_id = d.customer_id
group by d.occupation
go

--Average Income (per month)--
select 
	d.occupation, 
	sum(d.avg_income)/count(distinct(d.customer_id)) as 'Average income'
from dim_customers d
group by occupation
order by 'Average Income' desc
go

--every variables are from 1 month--
--utilisation--
with avg_monthly_spend as (
    select 
        d.occupation,
        (sum(f.spend)/count(distinct(f.customer_id)))/6 as avg_monthly_spend
    from dim_customers d
    join fact_spends f on f.customer_id = d.customer_id
    group by d.occupation
),
avg_income as (
    select 
        occupation,
        sum(avg_income)/count(distinct(customer_id)) as avg_income
    from dim_customers
    group by occupation
)
select
    s.occupation,
    s.avg_monthly_spend,
    i.avg_income,
    cast((cast(s.avg_monthly_spend as decimal(10,4)) / cast(i.avg_income as decimal(10,4)))*100 as decimal(4,2)) as spend_to_income_ratio
from avg_monthly_spend s
join avg_income i on s.occupation = i.occupation
order by spend_to_income_ratio desc
go

--Total spend for each categories by each payment type--
select	
	category,
	sum(case when payment_type = 'Credit Card' then spend else 0 end) as 'Credit Card',
	sum(case when payment_type = 'Debit Card' then spend else 0 end) as 'Debit Card',
	sum(case when payment_type = 'UPI' then spend else 0 end) as 'UPI',
	sum(case when payment_type = 'Net Banking' then spend else 0 end) as 'Net Banking'
from fact_spends
group by category
order by 'Credit Card' desc
go

--Top 10 customer who use credit card the most--
select 
	top (10) f.customer_id, 
	d.occupation, 
	d.age_group, 
	d.gender, 
	d.city, 
	d.marital_status, 
	sum(f.spend) as 'Total used by CC' 
from fact_spends f
join dim_customers d on d.customer_id = f.customer_id
where f.payment_type = 'Credit card'
group by f.customer_id, d.occupation, d.age_group, d.gender, d.city, d.marital_status
order by 'Total used by CC' desc

--Total Income--
select sum(avg_income)*6
from dim_customers
GO
