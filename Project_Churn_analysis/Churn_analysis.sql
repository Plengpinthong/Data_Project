select*from customer_info
select * from Location_Data
select * from Payment_Info
select * from Service_Options
select * from Online_Services
select * from Status_Analysis
use customer
go

--1. Basic information of Customers

--NUmber of all customers
select distinct(count(*)) from Customer_Info
	
--Number of Customers by Gender
with CountGender as (
	select
		gender,
		count(*) as 'Count_by_gender'
	from Customer_Info
	group by gender
),
	Total as (
	select
		count(gender) as 'Count_all'
	from Customer_Info
)
select
	gender,
	Count_by_gender,
	cast((cast(Count_by_gender AS DECIMAL(10,4)) / cast(Count_all AS DECIMAL(10,4)))*100 as decimal(4,2)) as 'Percent %'
from CountGender, Total
go

--Number of Customers by Age
with AgeGroup as (
	select
		customer_id,
		age,
		case
			when age between 0 and 15 then '0-15'
			when age between 16 and 30 then '16-30'
			when age between 31 and 45 then '31-45'
			when age between 46 and 55 then '46-55'
			when age between 56 and 65 then '0-15'
			when age > 65 then 'Above 65'
		end as 'Age_group'
	from Customer_Info
),
	CountAge as (
	select
		age_group,
		count(*) as 'Count_by_AgeGroup'
	from agegroup
	group by age_group
),
	Total as (
	Select
		Count(age) as 'All_customer'
	from Customer_Info
)
select
	age_group,
	Count_by_agegroup,
	cast((cast(count_by_agegroup AS DECIMAL(10,4)) / cast(All_customer AS DECIMAL(10,4)))*100 as decimal(4,2)) as 'Percent %'
from CountAge, Total
order by age_group
go

--Marital Status
with Customer_Status as (
	select
		customer_id,
		married,
		case
			when married = 1 then 'Married'
			else 'Single'
		end as 'Marital_Status'
	from Customer_Info
),
	Count_status as (
	select
		Marital_status,
		count(*) as 'Count_by_Status'
	from Customer_Status
	group by Marital_status
),
	Total as (
	select
		Count(married) as 'Allcustomer'
	from Customer_Info
)
select
	Marital_status,
	Count_by_Status,
	cast((cast(Count_by_status AS DECIMAL(10,4)) / cast(Allcustomer AS DECIMAL(10,4)))*100 as decimal(4,2)) as 'Percent %'
from Count_status, Total
go

--Satisfaction Score
select
	satisfaction_score,
	count(*) as 'Count of score'
from Status_Analysis
group by satisfaction_score
order by [Count of score] desc
go

--2. Churn Reason

--Number of Customers who Stayed and Churned
with Churn_stayed as (
	select
		customer_id,
		churn_value,
		case
			when churn_value = 0 then 'Stayed'
			else 'Churned'
		end as 'Churn_or_Stayed' 
	from Status_Analysis
)
select
	churn_or_stayed,
	count(*) 'Status_count'
from Churn_stayed
group by churn_or_stayed
go

--Churn reason
select
	churn_reason,
	count(*) 'Count_reason'
from Status_Analysis
where churn_reason not in ( 
					Select
						churn_reason
					from Status_Analysis
					where churn_reason = 'N/A')
group by churn_reason
order by Count_reason desc
go

--churn categories
select
	churn_category,
	count(*) as 'Count'
from Status_Analysis
where churn_category not in (
						select
							churn_category
						from Status_Analysis
						where churn_category = 'Not applicable')
group by churn_category
order by count desc
go

--Tenure of customers who Churned
with churned_customer as (
	Select
		so.tenure,
		p.customer_id,
		p.contract,
		cast(p.total_revenue as decimal(7,2)) as 'total_revenue'  ,
		sa.churn_value,
		sa.churn_category,
		sa.churn_reason
	from Payment_Info p
	join Service_Options so on so.customer_id = p.customer_id
	join Status_Analysis sa on sa.customer_id = p.customer_id
	where sa.churn_value = 1
),
	period as (
	select
		customer_id,
		tenure,
		case
			when tenure < 12 then 'Less than 1 year'
			when tenure between 12 and 24 then '1-2 year'
			when tenure between 25 and 36 then '2-3 year'
			when tenure between 37 and 48 then '3-4 year'
			when tenure between 49 and 60 then '4-5 year'
			else 'More than 5 years'
		end as 'tenure_period'
	from churned_customer
)
select 
	tenure_period,
	count(*) as 'Count_tenure'
from period
group by tenure_period
order by Count_tenure desc;
	--Customers who churned mostly stay with the company less than 1 year
--why did they leave too early
with one_year as (
	Select
		so.tenure,
		p.customer_id,
		p.contract,
		cast(p.total_revenue as decimal(7,2)) as 'total_revenue'  ,
		sa.churn_value,
		sa.churn_category,
		sa.churn_reason
	from Payment_Info p
	join Service_Options so on so.customer_id = p.customer_id
	join Status_Analysis sa on sa.customer_id = p.customer_id
	where sa.churn_value = 1 and tenure <=12
)
select
	churn_category,
	count(*) as 'Count'
from one_year
group by churn_category
order by Count desc
	--Answer: Because competitor made better offer.
--What about the customers who has been with us more than 5 years, why they decided to leave.
with five_year as (
	Select
		so.tenure,
		p.customer_id,
		p.contract,
		cast(p.total_revenue as decimal(7,2)) as 'total_revenue'  ,
		sa.churn_value,
		sa.churn_category,
		sa.churn_reason
	from Payment_Info p
	join Service_Options so on so.customer_id = p.customer_id
	join Status_Analysis sa on sa.customer_id = p.customer_id
	where sa.churn_value = 1 and tenure >60
)
select
	churn_category,
	count(*) as 'Count_why'
from five_year
group by churn_category
	--The answer is still because of the competitor
--Why competitor?
select
	churn_reason,
	count(*) as 'Count_of_reason'
from Status_Analysis
where churn_category = 'Competitor'
group by churn_reason
order by Count_of_reason desc
	--Because competitor had better devices.

--For higher download offer from competitor, what download speed did the customers had when they were with us?
with speed_group as (
	select
		so.avg_monthly_gb_download,
		count(*) as 'Count_speed',
		case
			when avg_monthly_gb_download between 0 and 30 then '0-30 gb'
			when avg_monthly_gb_download between 31 and 60 then '31-60 gb'
			when avg_monthly_gb_download > 60 then 'More than 60 gb'
		end as 'gb_speed'
	from Service_Options so
	join Status_Analysis sa on sa.customer_id = so.customer_id
	where churn_reason = 'Competitor offered higher download speeds'
	group by so.avg_monthly_gb_download
)
select
	gb_speed,
	count(*) as 'Count_gb_group'
from speed_group
group by gb_speed
order by Count_gb_group desc
	--Most of the customer who left beacause download speed, usually they got 0-30 gb, we can offer more download speed to make them stay. 

select
	so.offer,
	os.streaming_tv,
	count(*)
from online_services os
join service_options so on so.customer_id = os.customer_id
group by so.offer, os.streaming_tv
order by so.offer