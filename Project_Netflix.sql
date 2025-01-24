--1. Count the number of Movies vs TV Shows
select
	type, 
	count(type) 'Count'
from netflix
group by type
go

--2.Count all title released in each year
select
	release_year,
	count(type) as 'title'
from netflix
group by release_year
order by release_year
go

--3. Find the top 5 countries with the most content on Netflix
select
	top(5) country, 
	count(country) as 'Count_content'
from netflix
group by country
order by Count_content desc
go

--4. Identify the longest movie
with extract as (
	select 
		title,
		duration,
		cast(substring(duration,1,CHARINDEX(' ',duration) - 1) as int) as 'Minutes'
	from netflix
	where type = 'movie'
)
select
	title,
	duration,
	rank() over (order by Minutes desc) as 'Duration_rank'
from extract
go

--5. Find content added in the last 2017-2021 years
select
	*
from netflix
where release_year between 2017 and 2021
order by release_year asc
go

--6. Find all the movies/TV shows by director 'Rajiv Chilaka'!
select
	*
from netflix
where director = 'Rajiv Chilaka'
go

--7. List all TV shows with more than 5 seasons
with extractSeason as (
	select 
		title,
		cast(substring(duration,1,charindex(' ',duration)-1) as int) as 'Season'
	from netflix
	where type = 'tv show'
)
select 
	title,
	season
from extractSeason
where season > 5
order by season desc
go

--8. Count the number of content items in each genre
select
	listed_in as 'Genre',
	count(*) as 'Count Content'
from netflix
group by listed_in
order by [Count Content] desc
go

/*9.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!*/
select
	top(5) release_year,
	count(*) as 'Count_content'
from netflix
where country = 'India'
group by release_year
order by Count_content desc
go

--10. List all movies that are documentaries
select
	*
from netflix
where listed_in like '%Documentaries%'
go

--11. Find how many movies actor 'Salman Khan' appeared in last 10 years!
select
	count(*) as 'Salman Khan Movies'
from netflix
where cast like '%Salman Khan%' and release_year between 2012 and 2022
go

/*12.
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.*/
with categorized as (
	select
		type,
		title,
		description,
		case when description like '% Kill %' or description like '%violence%' then 'Bad' else 'Good'
		end as 'Categories'
	from netflix
)
select 
	type,
	categories, 
	count(*) as 'Count Category'
from categorized
group by Categories, type
go

