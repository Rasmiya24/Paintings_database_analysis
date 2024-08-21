CREATE TABLE museum_hours (
    museum_id INTEGER PRIMARY KEY,
    day VARCHAR,
    open TIME,
    close TIME
);

-- Create table for museum
CREATE TABLE museum (
    museum_id INTEGER PRIMARY KEY,
    name TEXT,
    address TEXT,
	city TEXT,
	state TEXT,
	postal VARCHAR,
	country TEXT,
	phone VARCHAR,
	url TEXT
);

-- Create table for product_size
CREATE TABLE product_size (
    work_id INTEGER PRIMARY KEY,
    size_id INTEGER,
    sale_price INTEGER,
    regular_price INTEGER
);

-- Create table for subject
CREATE TABLE subject (
    work_id INTEGER PRIMARY KEY,
    subject TEXT
);

-- Create table for work
CREATE TABLE work (
    work_id INTEGER PRIMARY KEY,
    name VARCHAR,
    artist_id INTEGER,
	style TEXT,
	museum_id INTEGER);

----------------------------------------------------------------

--- Fetch all the paintings which are not displayed on any museums?
	 SELECT *
	 FROM work
	 WHERE museum_id IS NULL;

--- How many paintings have an asking price of more than their regular price? 
	SELECT COUNT(*) 
	FROM product_size
	WHERE sale_price > regular_price;

--- Identify the paintings whose asking price is less than 50% of its regular price
	SELECT *
	FROM product_size
	WHERE sale_price < (regular_price*0.5);

--- Which canvas size costs the most?
	SELECT c.label, p.sale_price
	FROM product_size AS p
	JOIN canvas_size AS c
	ON p.size_id = c.size_id
	ORDER BY p.sale_price DESC
	LIMIT 1;

--- Delete duplicate records from work, product_size, subject and image_link tables
	DELETE FROM work
	WHERE work_id NOT IN (
		SELECT DISTINCT ON (work_id) work_id
		FROM work
		ORDER BY work_id);

	DELETE FROM product_size
	WHERE (work_id, size_id) NOT IN (
		SELECT DISTINCT ON (work_id, size_id) work_id, size_id
 		FROM product_size
 		ORDER BY work_id, size_id);

	DELETE FROM subject
	WHERE (work_id, subject) NOT IN (
  		SELECT DISTINCT ON (work_id, subject) work_id, subject
  		FROM subject
  		ORDER BY work_id, subject);

	DELETE FROM image_link
	WHERE work_id NOT IN (
  		SELECT DISTINCT ON (work_id) work_id
  		FROM image_link
  		ORDER BY work_id);

--- Identify the museums with invalid city information in the given dataset
	SELECT * 
	FROM museum 
	WHERE city ~ '^[0-9]';
		
--- Fetch the top 10 most famous painting subject
	SELECT * 
	FROM (
		SELECT s.subject, COUNT(1) AS no_of_paintings
		FROM WORK AS w
		JOIN subject AS s 
		ON s.work_id = w.work_id
		GROUP BY s.subject 
		ORDER BY no_of_paintings DESC
		LIMIT 10)
		
--- How many museums are open every single day?
	SELECT COUNT(*)
	FROM (
		SELECT museum_id
		FROM museum_hours
		GROUP BY museum_id
		HAVING COUNT(*) = 7);

--- Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
	SELECT m.name, m.city, m.country, COUNT(w.museum_id) AS no_of_paintings
	FROM work AS w
	JOIN museum AS m
	ON w.museum_id = m.museum_id
	GROUP BY w.museum_id, m.name, m.city, m.country
	ORDER BY no_of_paintings DESC
	LIMIT 5;
	
--- Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
	SELECT a.full_name AS artist, COUNT(w.artist_id) AS no_of_paintings
	FROM work AS w
	JOIN artist AS a
	ON a.artist_id = w.artist_id
	GROUP BY w.artist_id, artist
	ORDER BY no_of_paintings DESC
	LIMIT 5;

--- Display the 3 least popular canva sizes
	SELECT label, no_of_paintings
	FROM(
		SELECT cs.size_id, cs.label, COUNT(1) AS no_of_paintings
		FROM work w
		JOIN product_size AS ps
		ON ps.work_id = w.work_id
		JOIN canvas_size AS cs
		ON cs.size_id = ps.size_id
		GROUP BY cs.size_id, cs.label
	) AS subquery
	ORDER BY no_of_paintings 
	LIMIT 3;

--- Which museum is open for the longest during a day. Display museum name, state and hours open and which day?
	SELECT museum_name, state, open, close, day, hours_open
	FROM(
		SELECT m.name AS museum_name, m.state, mh.day, mh.open, mh.close, (mh.close - mh.open) AS hours_open
		FROM museum_hours AS mh
		JOIN museum AS m
		ON m.museum_id = mh.museum_id
	)	AS subquery
	WHERE hours_open = (
		SELECT MAX(close - open)
		FROM museum_hours
	)

--- Which museum has the most no of most popular painting style?
	WITH popular_style AS (
		SELECT style
		FROM work
		GROUP BY style
		ORDER BY COUNT(*) DESC
		LIMIT 1
	)
	SELECT m.name AS museum_name, w.style, COUNT(1) AS no_of_paintings 
	FROM work AS w
	JOIN museum AS m
	ON m.museum_id = w.museum_id
	WHERE w.style = (SELECT  style
					 FROM popular_style)
	GROUP BY m.name, w.style
	ORDER BY no_of_paintings DESC
	LIMIT 1;

--- Identify the artists whose paintings are displayed in multiple countries
	SELECT artist, COUNT(DISTINCT country) AS no_of_countries
	FROM 
		(SELECT DISTINCT a.full_name AS artist, m.country 
   		FROM work AS w 
   		JOIN artist AS a 
		ON a.artist_id = w.artist_id 
   		JOIN museum AS m 
		ON m.museum_id = w.museum_id) AS subquery
	GROUP BY artist
	HAVING COUNT(DISTINCT country) > 1
	ORDER BY 2 DESC;
	
--- Identify the artist and the museum where the most expensive and least expensive painting is placed. Display the artist name, sale_price, painting name, museum name, museum city and canvas label
	WITH most_expensive AS (
  	SELECT w.name AS painting, ps.sale_price, a.full_name AS artist, m.name AS museum, m.city, cs.label AS canvas
  	FROM product_size AS ps
  	JOIN work AS w ON w.work_id = ps.work_id
  	JOIN museum AS m ON m.museum_id = w.museum_id
 	JOIN artist AS a ON a.artist_id = w.artist_id
  	JOIN canvas_size AS cs ON cs.size_id = ps.size_id::NUMERIC
 	ORDER BY ps.sale_price DESC
  	LIMIT 1),
		least_expensive AS (
  	SELECT w.name AS painting, ps.sale_price, a.full_name AS artist, m.name AS museum, m.city, cs.label AS canvas
  	FROM product_size ps
  	JOIN work AS w ON w.work_id = ps.work_id
  	JOIN museum AS m ON m.museum_id = w.museum_id
  	JOIN artist AS a ON a.artist_id = w.artist_id
  	JOIN canvas_size AS cs ON cs.size_id = ps.size_id::NUMERIC
  	ORDER BY ps.sale_price 
  	LIMIT 1)
	SELECT * FROM most_expensive
	UNION ALL
	SELECT * FROM least_expensive;

--- Which country has the 5th highest no of paintings?
	SELECT country, no_of_paintings
	FROM (
		SELECT m.country, COUNT(1) AS no_of_paintings
		FROM work AS w
		JOIN museum AS m 
		ON m.museum_id = w.museum_id
		GROUP BY m.country
	) AS subquery
	ORDER BY no_of_paintings DESC
	LIMIT 5;
		
--- Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
	SELECT a.full_name AS artist_name, a.nationality, COUNT(1) AS no_of_paintings
	FROM work AS W
	JOIN artist AS a
	ON a.artist_id = w.artist_id
	JOIN subject AS s
	ON s.work_id = w.work_id
	JOIN museum AS m
	ON m.museum_id = w.museum_id
	WHERE s.subject = 'Portraits'
	AND m.country != 'USA'
	GROUP BY a.full_name, a.nationality
	ORDER BY no_of_paintings DESC
	LIMIT 1;