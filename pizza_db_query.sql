/* 
Table Info:
Time horizon --> 2015-01-01 to 2015-12-31

After data cleaning:
1. order_details --> 48,620 rows
2. orders --> 21,350 rows
3. pizza_types --> 32 rows
4. pizzas --> 96 rows
*/

-- Overview of general table -- 
	SELECT order_details_id,
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
	FROM order_details_cleaned od
	LEFT JOIN pizzas_cleaned p ON od.pizza_id = p.pizza_id
	LEFT JOIN pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
	LEFT JOIN orders_cleaned o ON od.order_id = o.order_id;

-- total qty by category (Classic, Supreme, Veggie, Chicken) --
SELECT category,
SUM(quantity) AS total_qty
FROM order_details_cleaned od
LEFT JOIN pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY category
ORDER BY total_qty DESC;

-- total sales amount ($) by category (Classic, Supreme, Chicken, Veggie) --
SELECT category,
ROUND(SUM(quantity * price)) AS total_sales_amt
FROM order_details_cleaned od
LEFT JOIN pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY category
ORDER BY total_sales_amt DESC;

WITH recursive result AS (
SELECT
order_details_id,
od.order_id,
pt.pizza_type_id,
`name`,
category,
ingredients,
size,
quantity,
price,
quantity * price AS sales_amt,
`date`,
DATE_FORMAT(`date`, '%b') as month_name,
`time`
FROM order_details_cleaned od
LEFT JOIN pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
LEFT JOIN orders_cleaned o ON od.order_id = o.order_id),

result1 as (
select `name`, category, ingredients, sum(quantity) as total_qty
from result
group by `name`, ingredients, category
order by total_qty DESC
limit 10
),
-- To unpivot each ingredient into separate rows for COUNT() -- 
unpivot_result AS (
        SELECT
            name,
            category,
            SUBSTRING_INDEX(ingredients, ',', 1) AS split_value,
            IF(LOCATE(',', ingredients) > 0, SUBSTRING(ingredients, LOCATE(',', ingredients) + 1), NULL) AS remaining_values
        FROM
            result1
        UNION ALL
        SELECT
            name,
            category,
            SUBSTRING_INDEX(remaining_values, ',', 1) AS split_value,
            IF(LOCATE(',', remaining_values) > 0, SUBSTRING(remaining_values, LOCATE(',', remaining_values) + 1), NULL)
        FROM
            unpivot_result
        WHERE
            remaining_values IS NOT NULL
),

result2 AS (
SELECT `name`, category, trim(split_value) as ingredient
FROM unpivot_result)

SELECT ingredient, COUNT(ingredient) AS total_count
FROM result2
GROUP BY ingredient
ORDER BY total_count DESC;

-- Find Average Order Quantity & Revenue (across all categories) --
WITH unique_order AS (
SELECT order_details_id,
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
FROM order_details_cleaned od
LEFT JOIN pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
LEFT JOIN orders_cleaned o ON od.order_id = o.order_id),

total_revenue_per_order AS (
SELECT order_id,
SUM(quantity) as total_qty,
SUM(sales_amt) as total_revenue
FROM unique_order
GROUP BY order_id)

SELECT ROUND(AVG(total_qty), 2) AS avg_qty, ROUND(AVG(total_revenue), 2) AS avg_revenue
FROM total_revenue_per_order;


-- Market Basket Analysis (support/confidence/lift) -- 

WITH overview_table AS (
SELECT order_details_id,
od.order_id,
`name`
FROM order_details_cleaned od
LEFT JOIN pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
LEFT JOIN orders_cleaned o ON od.order_id = o.order_id),

transaction_table AS (
SELECT 
od.order_id,
COUNT(od.order_id) as total_count
FROM order_details_cleaned od
LEFT JOIN pizzas_cleaned p ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types_cleaned pt ON p.pizza_type_id = pt.pizza_type_id
LEFT JOIN orders_cleaned o ON od.order_id = o.order_id
GROUP BY od.order_id),


orders_basketsize_morethan1_table AS (
SELECT ot.order_id,
`name`
FROM overview_table ot
INNER JOIN transaction_table tt ON ot.order_id = tt.order_id),

# Removed rows where product1 = product2
orders_basketsize_morethan1_table2 AS (
SELECT t1.order_id, t1.`name` AS product1, t2.`name` AS product2
FROM orders_basketsize_morethan1_table t1
INNER JOIN orders_basketsize_morethan1_table t2 ON t1.order_id = t2.order_id
WHERE t1.`name` <> t2.`name`)

select * from orders_basketsize_morethan1_table2 where order_id = 1;















