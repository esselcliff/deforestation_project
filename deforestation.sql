
DELETE FROM forest_area WHERE forest_area_sqkm is NULL;
DELETE FROM land_area WHERE total_area_sq_mi is NULL;

/* DROP VIEW if exists forestation; */
CREATE OR REPLACE VIEW forestation as
SELECT  f.country_code, f.country_name, f.year, f.forest_area_sqkm,
        l.total_area_sq_mi * 2.59 AS total_area_sqkm,
        r.region, r.income_group,
        f.forest_area_sqkm / (l.total_area_sq_mi * 2.59) * 100 as percent_forest
FROM  forest_area f
JOIN land_area l
ON f.country_code = l.country_code
  AND f.year = l.year
LEFT JOIN regions r
ON f.country_code = r.country_code;


 
 
/* total forest area of World, 1990 */
SELECT SUM(forest_area_sqkm)
FROM forestation
WHERE year = 1990
AND country_name LIKE 'World';

/* total forest area of World, 2016 */
SELECT SUM(forest_area_sqkm)
FROM forestation
WHERE year = 2016
AND country_name LIKE 'World';

/* get difference in forest area lost */
SELECT 
  (SELECT SUM(forest_area_sqkm)
  FROM forestation
  WHERE year = 1990
  AND country_name LIKE 'World') -
  (SELECT SUM(forest_area_sqkm)
  FROM forestation
  WHERE year = 2016
  AND country_name LIKE 'World') diff;

/* get prop_change in forest area lost */
SELECT 
  (((SELECT SUM(forest_area_sqkm)
  FROM forestation
  WHERE year = 1990
  AND country_name LIKE 'World') -
  (SELECT SUM(forest_area_sqkm)
  FROM forestation
  WHERE year = 2016
  AND country_name LIKE 'World')) /
      (SELECT SUM(forest_area_sqkm)
      FROM forestation
      WHERE year = 1990
      AND country_name LIKE 'World')) * 100 percent_loss;


       
SELECT country_name, total_area_sqkm
FROM forestation
WHERE total_area_sqkm < 
    (SELECT 
      (SELECT SUM(forest_area_sqkm)
      FROM forestation
      WHERE year = 1990
      AND country_name LIKE 'World') -
      (SELECT SUM(forest_area_sqkm)
      FROM forestation
      WHERE year = 2016
      AND country_name LIKE 'World') diff)
GROUP BY 1, 2
ORDER BY 2 DESC 
LIMIT 1;
       
/* percent of forest land, 2016 */
SELECT year, region, percent_forest
FROM forestation
WHERE year = 2016
AND country_name LIKE 'World'
ORDER BY 3 DESC
LIMIT 1;     
       
/* region with highest relative forest */
DROP VIEW if exists relative_forest;
CREATE VIEW relative_forest as
SELECT year, region,
       SUM(forest_area_sqkm)/SUM(total_area_sqkm) * 100 relative_forest
FROM forestation
GROUP BY 1, 2;

/* region with highest relative forest, 2016 */
SELECT region, relative_forest
FROM relative_forest
WHERE year = 2016
ORDER BY 2 DESC
LIMIT 1; 

/* region with lowest relative forest, 2016 */
SELECT year, region, relative_forest
FROM relative_forest
WHERE year = 2016
ORDER BY 3 
LIMIT 1; 
       
/* forest percent of land, 1990 */
SELECT year, percent_forest
FROM forestation
WHERE year = 1990
AND country_name LIKE 'World';
       
/* region with highest relative forest, 1990 */
SELECT region, relative_forest
FROM relative_forest
WHERE year = 1990
ORDER BY 2 DESC
LIMIT 1; 
       
/* region with lowest relative forest, 1990 */
SELECT region, relative_forest
FROM relative_forest
WHERE year = 1990
ORDER BY 2 
LIMIT 1; 

WITH t1_2016 as (
  SELECT region, relative_forest
  FROM relative_forest
  WHERE year = 2016
  ORDER BY 2 DESC
  ), t2_1990 as (
   SELECT region, relative_forest
  FROM relative_forest
  WHERE year = 1990
  ORDER BY 2 DESC
    )
 
SELECT t1_2016.region, t2_1990.relative_forest percentage_forest_1990,
       t1_2016.relative_forest percentage_forest_2016
FROM t1_2016
JOIN t2_1990
ON t1_2016.region = t2_1990.region;       
    

  WITH t1_2016 as (
    SELECT region, relative_forest
    FROM relative_forest
    WHERE year = 2016
    ORDER BY 2 DESC
    ), t2_1990 as (
     SELECT region, relative_forest
    FROM relative_forest
    WHERE year = 1990
    ORDER BY 2 DESC
      )
      SELECT t1_2016.region, t2_1990.relative_forest percentage_forest_1990,
           t1_2016.relative_forest percentage_forest_2016
    FROM t1_2016
    JOIN t2_1990
    ON t1_2016.region = t2_1990.region
    WHERE t1_2016.relative_forest < t2_1990.relative_forest
    AND t1_2016.region != 'World';

       
/* COUNTRY LEVEL DETAIL */
/* A. Success stories */
WITH t1 as(
  SELECT country_name, forest_area_sqkm
  FROM forestation
  WHERE year = 1990
), t2 as (
  SELECT country_name, forest_area_sqkm
  FROM forestation
  WHERE year = 2016
), t3 as (
SELECT t1.country_name, 
        t1.forest_area_sqkm forest_area_sqkm_1990,
        t2.forest_area_sqkm forest_area_sqkm_2016
FROM t1 JOIN t2
ON t1.country_name = t2.country_name    
)
SELECT t3.country_name,
      t3.forest_area_sqkm_1990,
      t3.forest_area_sqkm_2016,
      t3.forest_area_sqkm_2016 - t3.forest_area_sqkm_1990 diff,
(t3.forest_area_sqkm_2016 - t3.forest_area_sqkm_1990) / t3.forest_area_sqkm_1990 * 100 percent_change
FROM t3
WHERE forest_area_sqkm_1990 < forest_area_sqkm_2016 
ORDER BY 5 DESC
LIMIT 2;
       
/* Largest concerns */
/* Deforestation */
WITH t1 as(
  SELECT country_name, region, forest_area_sqkm
  FROM forestation
  WHERE year = 1990
), t2 as (
  SELECT country_name, region, forest_area_sqkm
  FROM forestation
  WHERE year = 2016
), t3 as (
SELECT t1.country_name, t1.region,
        t1.forest_area_sqkm forest_area_sqkm_1990,
        t2.forest_area_sqkm forest_area_sqkm_2016
FROM t1 JOIN t2
ON t1.country_name = t2.country_name
)

SELECT t3.country_name, t3.region,
      ABS(t3.forest_area_sqkm_2016 - t3.forest_area_sqkm_1990) abs_diff_sqkm,
      (t3.forest_area_sqkm_2016 - t3.forest_area_sqkm_1990) / t3.forest_area_sqkm_1990 * 100 percentage_change
FROM t3
WHERE forest_area_sqkm_1990 > forest_area_sqkm_2016
AND country_name NOT LIKE 'World'
/*  choose order by percentage_change or abs_diff_sqkm to ans question */
ORDER BY percentage_change 
LIMIT 5;

/* QUARTILES */
CREATE OR REPLACE VIEW quart_table as
    SELECT country_name, region, percent_forest,
          CASE  WHEN percent_forest < 25 THEN 1
                WHEN percent_forest < 50 THEN 2
                WHEN percent_forest < 75 THEN 3
                ELSE 4 END AS quartile
    FROM forestation
    WHERE year = 2016;

SELECT quartile, count(*)
FROM quart_table
GROUP BY quartile
ORDER BY quartile;

/* top quartile countries */
SELECT country_name, region, percent_forest
FROM quart_table
WHERE quartile = 4
ORDER BY percent_forest DESC;
       
SELECT * FROM regions;
       
SELECT r.income_group, r.country_name, f.forest_area_sqkm
FROM regions r
JOIN forest_area f
ON r.country_name = f.country_name
WHERE f.year = 2016
ORDER BY r.income_group, f.forest_area_sqkm desc; 


CREATE TABLE IF NOT EXISTS students_1  
(student_id int,   
student_name varchar(250),   
student_address varchar(250),  
student_weight int);

SELECT income_group, country_name, forest_area_sqkm
FROM      
  (SELECT r.income_group, r.country_name, f.forest_area_sqkm,
       ROW_NUMBER() OVER (PARTITION BY income_group ORDER BY forest_area_sqkm DESC) as ranK
  FROM regions r
  JOIN forest_area f
  ON r.country_name = f.country_name
  WHERE f.year = 2016
  AND f.forest_area_sqkm != 0
  AND f.country_name != 'World'
  ORDER BY r.income_group, f.forest_area_sqkm desc) t
WHERE rank <= 3; 
