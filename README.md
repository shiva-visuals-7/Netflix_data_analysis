# Netflix Movies and TV Shows Data Analysis using SQL

![](netflix-logo.png)

## Overview
This project focuses on analyzing Netflix's movie and TV show data using SQL. The goal is to gain useful insights and answer key business questions based on the dataset. This README outlines the project's purpose, problems, solutions, key findings, and conclusions.

## Objectives

- Compare the number of movies and TV shows.
- Find the most common ratings for both.
- Analyze content by release year, country, and duration.
- Categorize content based on specific keywords and trends.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)
- **Source:** Kaggle
- **Size:** 8807 rows, 12 columns

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5) primary key,
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
```


## 🛠️ Tools & Technologies Used
- Microsoft Sql - for solving business problems
- VS Code - for pushing into github repository

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
select type, COUNT(*) [total count] 
from netflix_titles
group by type
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
select type, rating 
from 
(
select type, rating, COUNT(*) [count],
RANK() over(partition by type order by count(*) desc) [ranking]
from netflix_titles
group by type, rating
) AS t1
where ranking=1
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
select * 
from netflix_titles 
where type = 'Movie' and release_year = 2020
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
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
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
SELECT 
    Title, 
    Duration
FROM netflix_titles
WHERE CAST(LEFT(Duration, CHARINDEX(' ', Duration) - 1) AS INT) = (
    SELECT MAX(CAST(LEFT(Duration, CHARINDEX(' ', Duration) - 1) AS INT))
    FROM netflix_titles
    WHERE Type = 'Movie'
) AND Type = 'Movie'
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
select * 
from netflix_titles
where date_added >= DATEADD(YEAR, -5, GETDATE())
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
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
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
select show_id, type, title
from netflix_titles
WHERE CAST(LEFT(Duration, CHARINDEX(' ', Duration) - 1) AS INT) > 5
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
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
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
select top 5 YEAR(CAST(date_added AS DATE)) [year],
COUNT(*) [content release], 
cast(COUNT(*) as float)/(select COUNT(*) from netflix_titles where country like '%India%') * 100 [avg content release] 
from netflix_titles
where country like '%India%'
group by YEAR(CAST(date_added AS DATE))
order by [avg content release] desc
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
select * 
from netflix_titles
where type = 'movie' and listed_in like '%documentaries%'
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
select * from netflix_titles
where director IS NULL
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql

--according to release_year

select * 
from netflix_titles
where type = 'movie' and cast like '%salman khan%' and release_year >= YEAR(GETDATE()) - 10

--OR according to date_added

select * 
from netflix_titles
where type = 'movie' and cast like '%salman khan%' and
date_added >= DATEADD(YEAR, -10, GETDATE())
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
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
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
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
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** Netflix offers a wide variety of movies and TV shows across different genres and ratings.
- **Common Ratings:** Identifying the most frequent ratings helps understand the target audience.
- **Geographical Insights:** Analyzing top countries and India's content output reveals regional distribution patterns.
- **Content Categorization:** Grouping content by keywords provides insights into the types of shows and movies available.


This analysis gives a clear picture of Netflix's content and can support better content strategy and decision-making.


## Author - shiva

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, feel free to get in touch!

### Contact:
- **Email:** venkatashiva2802@gmail.com
- [LinkedIn](https://www.linkedin.com/in/venkata-shiva-b913a0211)
- [Github](https://github.com/shiva-visuals-7)
