
-- 15 Business Problems & Solutions

select * from netflix_titles

--1. Count the number of Movies vs TV Shows

select type, COUNT(*) [total count] 
from netflix_titles
group by type


--2. Find the most common rating for movies and TV shows

select type, rating 
from 
(
select type, rating, COUNT(*) [count],
RANK() over(partition by type order by count(*) desc) [ranking]
from netflix_titles
group by type, rating
) AS t1
where ranking=1


--3. List all movies released in a specific year (e.g., 2020)

select * 
from netflix_titles 
where type = 'Movie' and release_year = 2020


--4. Find the top 5 countries with the most content on Netflix

WITH CountrySplit AS (
    SELECT
        show_id, -- Assuming each row has a unique Show_ID
        LTRIM(RTRIM(value)) AS Countries -- Trim extra spaces from split values
    FROM 
        netflix_titles
        CROSS APPLY STRING_SPLIT(Country, ',') -- Split country column by commas
)
SELECT TOP 5 
    Countries, 
    COUNT(*) AS ContentCount
FROM CountrySplit
GROUP BY Countries
ORDER BY ContentCount DESC


--5. Identify the longest movie

SELECT 
    Title, 
    Duration
FROM netflix_titles
WHERE CAST(LEFT(Duration, CHARINDEX(' ', Duration) - 1) AS INT) = (
    SELECT MAX(CAST(LEFT(Duration, CHARINDEX(' ', Duration) - 1) AS INT))
    FROM netflix_titles
    WHERE Type = 'Movie'
) AND Type = 'Movie'


--6. Find content added in the last 5 years

select * 
from netflix_titles
where date_added >= DATEADD(YEAR, -5, GETDATE())


--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

--With commom table expressions (CTEs)
with direction as(
 SELECT
        show_id, type, title, ---- Assuming each row has a unique Show_ID
        LTRIM(RTRIM(value)) AS director -- Trim extra spaces from split values
    FROM 
        netflix_titles
        CROSS APPLY STRING_SPLIT(director, ',') 
)
select * 
from direction
where director = 'Rajiv Chilaka'

--OR with like function
select * 
from netflix_titles
where director like '%Rajiv Chilaka%'


--8. List all TV shows with more than 5 seasons

select show_id, type, title
from netflix_titles
WHERE CAST(LEFT(Duration, CHARINDEX(' ', Duration) - 1) AS INT) > 5


--9. Count the number of content items in each genre

WITH genresplit AS (
    SELECT
        show_id, type, title, -- Assuming each row has a unique Show_ID
        LTRIM(RTRIM(value)) AS listings -- Trim extra spaces from split values
    FROM 
        netflix_titles
        CROSS APPLY STRING_SPLIT(listed_in, ',') -- Split country column by commas
)
SELECT listings, 
    COUNT(distinct show_id) AS ContentCount
FROM genresplit
GROUP BY listings
ORDER BY ContentCount DESC


--10.Find each year and the average numbers of content release in India on netflix. 
--return top 5 year with highest avg content release!

select top 5 YEAR(CAST(date_added AS DATE)) [year],
COUNT(*) [content release], 
cast(COUNT(*) as float)/(select COUNT(*) from netflix_titles where country like '%India%') * 100 [avg content release] 
from netflix_titles
where country like '%India%'
group by YEAR(CAST(date_added AS DATE))
order by [avg content release] desc


--11. List all movies that are documentaries

select * 
from netflix_titles
where type = 'movie' and listed_in like '%documentaries%'


--12. Find all content without a director

select * from netflix_titles
where director IS NULL


--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

--according to release_year
select * 
from netflix_titles
where type = 'movie' and cast like '%salman khan%' and release_year >= YEAR(GETDATE()) - 10

--OR according to date_added

select * 
from netflix_titles
where type = 'movie' and cast like '%salman khan%' and
date_added >= DATEADD(YEAR, -10, GETDATE())


--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

WITH CastSplit AS (
    SELECT
        show_id, -- Assuming each row has a unique Show_ID
        LTRIM(RTRIM(value)) AS actors -- Trim extra spaces from split values
    FROM 
        netflix_titles
        CROSS APPLY STRING_SPLIT(cast, ',') -- Split country column by commas
		where country like '%India%'
)
SELECT TOP 10 
    actors, 
    COUNT(*) AS ContentCount
FROM CastSplit
GROUP BY actors
order by ContentCount desc


/*15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.*/

with new_col as
(
select *,
case
	when 
		description like '%kill%' OR
		description like '%violence%' then 'bad_content'
		else 'good_content'
	end category
from netflix_titles
)
select category, COUNT(*) [content count]
from new_col
group by category


