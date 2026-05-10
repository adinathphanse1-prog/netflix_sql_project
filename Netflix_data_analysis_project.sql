-- 1. Count the number of Movies vs TV Shows

select type, count(*) as total_content
from netflix_titles
group by type;

-- Count the number of Movies is 6131 and TV Shows 2676

-- 2. Find the most common rating for movies and TV shows

select *
from
(select type, rating, count(*) as count_of_rating,
dense_rank() over ( partition by type order by count(*) desc) as raking 
from netflix_titles
group by 1,2) as t
where raking = 1;
-- most common rating for movies 2062 and tv shows 1145 is TV-MA

-- 3. List all movies released in a specific year (e.g., 2020)

select title, type, release_year
from netflix_titles
where type = 'Movie' and release_year = 2020;

select release_year, count(*)
from netflix_titles
where type = 'Movie' and release_year = 2020
group by 1;

-- there are total 517 movies released on netflix in year 2020

-- 4. Find the top 5 countries with the most content on Netflix

select country, count(*) as count_of_content
from netflix_titles
group by country
order by count_of_content desc
limit 5;

SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', n), ',', -1)) AS new_country,
    COUNT(show_id) AS total_content
FROM netflix_titles
JOIN (
    SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 
    UNION ALL SELECT 4 UNION ALL SELECT 5
) numbers
ON n <= 1 + LENGTH(country) - LENGTH(REPLACE(country, ',', ''))
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;


-- 5 Identify the longest movie

SELECT title, duration,type
FROM netflix_titles
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
limit 5;


select title, duration
from netflix_titles 
where type = 'Movie' and duration = (select max(duration) from netflix_titles); 

--  Identify the longest movie is Black Mirror: Bandersnatch	312 min

--  6. Find content added in the last 5 years

select *
from netflix_titles
where to_days(date_added, 'Month DD', 'YYYY') >= CURRENT_DATE - INTERVAL '5 years';


-- my code/ gpt code
SELECT type, title
FROM netflix_titles
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 5 YEAR;


SELECT * 
FROM
(
    SELECT country,
        COUNT(*) AS total_content
    FROM netflix_titles
    GROUP BY 1
) AS t1
WHERE country is NOT NULL
ORDER BY total_content DESC
LIMIT 5;

-- or we use trim if there is any space in the 
SELECT country,
       COUNT(*) AS total_content
FROM netflix_titles
WHERE country is not null and TRIM(country) <> ''
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;

-- 7 find out the tv shows and movies which directed by rajiv chilaka.

 select type, director,title
 from netflix_titles
 where director like '%Rajiv Chilaka%'; -- use also use Ilike operator for find the if name is not in case sensetive.
 
 

-- 8 list all tv show with more than 5 seasons
-- my code
select title, duration
from netflix_titles
where type = 'Tv Show' AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5; -- neither you can you split function also after and operator
-- sir code
select title, duration
from netflix_titles
where type = 'Tv Show' AND spilt_part(duration, ' ', 1);


-- 9 count the number of content item in each genre

-- my code
select listed_in, count(*)
from netflix_titles
group by listed_in;

WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM numbers
    WHERE n < 10
)

SELECT 
    TRIM(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(listed_in, ',', n),
            ',',
            -1
        )
    ) AS genre,
    COUNT(*) AS total_content
FROM netflix_titles
JOIN numbers
ON n <= 1 + LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', ''))
GROUP BY genre
ORDER BY total_content desc;

-- sir code
select unnest(string_to_array(listing_in, ',')) as genre,
count(show_id) as total_content
from netflix_titles
group by 1;


-- 10 find each year the average numbers of content release by india on netflix. 
-- return top 5 years with highest avg content release

select extract(YEAR from TO_DATE(date_added, 'Month DD, YYYY')) as year,
count(*) As yearly_content,
round(count(*) :: numeric / (select count (*) from netflix_titles where country = 'India'):: numeric * 100,2 as avg_content_per_year
from netflix_titles
where country = 'India'
group by 1
ORDER BY avg_content_per_year desc
limit 5;

-- my code / gpt
SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year,
    
    COUNT(*) AS yearly_content,
    
    ROUND(
        COUNT(*) / 
        (SELECT COUNT(*) 
         FROM netflix_titles 
         WHERE country = 'India') * 100,
        2
    ) AS avg_content_per_year

FROM netflix_titles

WHERE country = 'India'

GROUP BY YEAR(STR_TO_DATE(date_added, '%M %d, %Y'))

ORDER BY avg_content_per_year desc
limit 5;


-- 11 list all movies that are documentries

select *
from netflix_titles
where listed_in like '%Documentaries%';



-- 12 Find a contact without a director 

SELECT *
FROM netflix_titles
WHERE director IS NULL OR director = '';


-- 13 find how many actor 'salman khan' appeared in last 10 years

select *
from netflix_titles
where cast like '%Salman khan%' and release_year > extract(year from current_date) - 10
order by release_year;

-- find the top ten actors who have appreard in the highest number of movies produced in india.->

select cast, count(*) as total_movies, unnest(string to array(cast, ',')) as actors
from netflix_titles
where country = 'India'
group by 1;


WITH RECURSIVE actor_split AS (

    -- First actor
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(`cast`, ',', 1)) AS actor,
        SUBSTRING(
            `cast`,
            LENGTH(SUBSTRING_INDEX(`cast`, ',', 1)) + 2
        ) AS remaining
    FROM netflix_titles
    WHERE country = 'India'
      AND `cast` IS NOT NULL

    UNION ALL

    -- Remaining actors
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS actor,
        SUBSTRING(
            remaining,
            LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2
        ) AS remaining
    FROM actor_split
    WHERE remaining <> '')
    SELECT
    actor,
    COUNT(*) AS total_content
FROM actor_split
GROUP BY actor
ORDER BY total_content DESC
LIMIT 10;


/*15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category*/

SELECT 
    CASE
        WHEN description LIKE '%kill%'
          OR description LIKE '%violence%'
        THEN 'Bad'
        ELSE 'Good'
    END AS content_label,
    
    COUNT(*) AS total_content

FROM netflix_titles

GROUP BY content_label;












 
 















