#Create database and import food_name and details table through wizard
CREATE DATABASE nutrition_facts;

#Selecting the database and looking at the tables
USE nutrition_facts;

SELECT 
    *
FROM
    details;
    
SELECT 
    *
FROM
    food_name;
    
#Foods with under 100 Calories
SELECT
    f.item,
    ROUND(AVG(d.calorie), 0) AS calorie
FROM
	details d 
JOIN food_name f ON d.id = f.id
WHERE calorie <= 100
GROUP BY f.item
ORDER BY calorie DESC, item;

#High Protein Foods - top 100
SELECT * FROM (
SELECT
	f.item,
    ROUND(AVG(d.protein), 1) AS protein,
    RANK() OVER ( ORDER BY ROUND(AVG(d.protein), 1) DESC) AS protein_rank
FROM
	details d 
JOIN food_name f ON d.id = f.id
GROUP BY f.item) subquery
WHERE protein_rank <=100
ORDER BY protein DESC;

#Temporary Table for Fats
CREATE TEMPORARY TABLE fat_info AS
	SELECT
		d.id,
        f.item,
        f.item_detail,
		d.fat_sat,
        d.fat_mono,
        d.fat_poly,
        ROUND(SUM(d.fat_sat + d.fat_mono + d.fat_poly), 3) AS total_fats
	FROM
		details d
	JOIN
		food_name f ON d.id = f.id
	GROUP BY d.id, f.item, f.item_detail, d.fat_sat, d.fat_mono, d.fat_poly;

#Highest Fat Foods - top 100
SELECT * FROM(
SELECT 
    item, 
    ROUND(AVG(total_fats), 1) AS fats,
    RANK() OVER ( ORDER BY ROUND(AVG(total_fats), 1) DESC) AS fat_ranking
FROM
    fat_info
GROUP BY 
	item) subquery
WHERE fat_ranking <=100
ORDER BY fats DESC;

#Highest Carbohydrate Foods - top 100
SELECT * FROM(
SELECT
	f.item,
    ROUND(AVG(d.sugar), 1) AS sugar,
    ROUND(AVG(d.fibre), 1 ) AS fibre,
    ROUND(AVG(d.carbohydrate), 1) AS carbohydrate,
    RANK() OVER( ORDER BY ROUND(AVG(d.carbohydrate), 1) DESC) AS carb_ranking
FROM
	details d 
JOIN food_name f ON d.id = f.id
GROUP BY f.item) subquery
WHERE carb_ranking <=100
ORDER BY carbohydrate DESC, fibre DESC, sugar DESC, item;

#Highest Fibre Foods - top 100
SELECT * FROM(
SELECT
	f.item,
    ROUND(AVG(d.carbohydrate), 1) AS carbohydrate,
    ROUND(AVG(d.sugar), 1) AS sugar,
    ROUND(AVG(d.fibre), 1 ) AS fibre,
    RANK() OVER ( ORDER BY ROUND(AVG(d.fibre), 1) DESC) AS fibre_ranking
FROM
	details d 
JOIN food_name f ON d.id = f.id
GROUP BY f.item) subquery
WHERE fibre_ranking <=100
ORDER BY fibre DESC, carbohydrate DESC, item;	

#Items with variety (has item_detail)
SELECT
	item,
    COUNT(item) AS total_item
FROM
	food_name
GROUP BY
	item
HAVING total_item >1
ORDER BY total_item DESC;

#View Items and their varieties(details)
WITH variety_cte AS (
	SELECT
	item,
    COUNT(item) AS total_item
FROM
	food_name
GROUP BY
	item
HAVING total_item >1)
SELECT
	v.item,
    f.item_detail
FROM
	variety_cte v
JOIN food_name f ON f.item = v.item
ORDER BY v.item, f.item_detail;

#Food, calorie, and macro-nutrient info
CREATE TEMPORARY TABLE name_nutrition AS
SELECT
	n.item AS item,
    CONCAT_WS(' - ', MIN(d.calorie),MAX(d.calorie)) AS calorie_range_100g,
    CONCAT_WS(' - ', MIN(d.protein),MAX(d.protein)) AS protein_range_100g,
    CONCAT_WS(' - ', MIN(f.total_fats),MAX(f.total_fats)) AS fat_range_100g
FROM
	details d 
JOIN food_name n ON d.id = n.id
JOIN fat_info f ON n.item = f.item
GROUP BY n.item
ORDER BY n.item;

SELECT 
	*
FROM
	name_nutrition;
    
#create stored procedure to input item then show calorie and macro info
DROP PROCEDURE IF EXISTS nutrition_facts;
DELIMITER $$
CREATE PROCEDURE nutrition_facts (IN search_item VARCHAR(50))
BEGIN
  SELECT * FROM name_nutrition WHERE item = search_item;
END $$
DELIMITER ;

CALL nutrition_facts('corn');
