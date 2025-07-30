/* 
Table Info:
Time horizon --> 2015-01-01 to 2015-12-31
1. order_details --> 48,620 rows
2. orders --> 21,350 rows
3. pizza_types --> 32 rows
4. pizzas --> 96 rows
*/

-- Data Cleaning/Transformation & Exploratory Data Analysis-- 

-- Overview of table -- 
SELECT 
	order_details_id,
	od.order_id,
	pt.pizza_type_id,
	`name`,
	category,
	size,
	quantity,
	price,
	quantity * price AS sales_amt,
	`date`,
	DATE_FORMAT(`date`, '%b') as month_name,
	`time`
FROM 
	order_details_cleaned od
LEFT JOIN 
	pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN 
	pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
LEFT JOIN 
	orders_cleaned o ON od.order_id = o.order_id;

-- Assess the popularity of pizza categories (Classic, Supreme, Veggie, Chicken) based on total qty --
SELECT 
	category,
	SUM(quantity) AS total_qty
FROM 
	order_details_cleaned od
LEFT JOIN 
	pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN 
	pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 
	category
ORDER BY 
	total_qty DESC;

-- Examine the revenue contribution ($) by pizza categories (Classic, Supreme, Chicken, Veggie) --
SELECT 
	category,
	ROUND(SUM(quantity * price)) AS total_sales_amt
FROM 
	order_details_cleaned od
LEFT JOIN 
	pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN 
	pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 
	category
ORDER BY 
	total_sales_amt DESC;

-- Initial table --
WITH RECURSIVE t1 AS (
	SELECT 
		`name`,
		ingredients,
		category,
	FROM 
		pizza_types
),
-- To split each pizza's ingredients into separate rows based on ',' delimiter
t2 AS (
        SELECT
            	name,
            	category,
            	SUBSTRING_INDEX(ingredients, ',', 1) AS split_value,
            	IF(LOCATE(',', ingredients) > 0, SUBSTRING(ingredients, LOCATE(',', ingredients) + 1), NULL) AS remaining_values
        FROM
           	 t1
        UNION ALL
        SELECT
            	name,
	            category,
	            SUBSTRING_INDEX(remaining_values, ',', 1) AS split_value,
	            IF(LOCATE(',', remaining_values) > 0, SUBSTRING(remaining_values, LOCATE(',', remaining_values) + 1), NULL)
        FROM
            	t2
        WHERE
           	remaining_values IS NOT NULL
),
-- Remove leading and trailing spaces from each value of 'ingredient' column
t3 AS (
	SELECT `name`, 
		category,
		trim(split_value) AS ingredient
	FROM 
		t2
),
-- Examine which ingredients that are widely used across the pizza menu
SELECT 
	ingredient, 
	COUNT(ingredient) AS total_count
FROM 
	t3
GROUP BY 
	ingredient
ORDER BY 
	total_count DESC;

-- Assess Average Order Quantity & Average Revenue across all pizza categories --
WITH unique_order AS (
	SELECT 
		order_details_id,
		od.order_id,
		pt.pizza_type_id,
		`name`,
		category,
		size,
		quantity,
		price,
		quantity * price AS sales_amt,
		`date`,
		DATE_FORMAT(`date`, '%b') as month_name,
		`time`
	FROM 
		order_details_cleaned od
	LEFT JOIN 
		pizzas_cleaned p ON od.pizza_id = p.pizza_id
	LEFT JOIN 
		pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
	LEFT JOIN 
		orders_cleaned o ON od.order_id = o.order_id
),

total_revenue_per_order AS (
	SELECT 
		order_id,
		SUM(quantity) as total_qty,
		SUM(sales_amt) as total_revenue
	FROM 
		unique_order
	GROUP BY 
		order_id
),
	
SELECT 
	ROUND(AVG(total_qty), 2) AS avg_qty, 
	ROUND(AVG(total_revenue), 2) AS avg_revenue
FROM 
	total_revenue_per_order;
