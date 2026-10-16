/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
-- Which categories contribute the most to overall sales?
WITH category_sales AS (
    SELECT 
        p.category,
        SUM(s.sales_amount) total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
    ON s.product_key = p.product_key
    GROUP BY p.category
)
SELECT
*,
SUM(total_sales) OVER () as overall_sales,
CONCAT(ROUND(CAST(total_sales AS FLOAT)/SUM(total_sales) OVER ()*100,2),'%') AS percentage_of_total
FROM category_sales
ORDER by percentage_of_total DESC

-- Find a client that contribute the most
WITH cte_sales AS
(
    SELECT 
        CONCAT(c.first_name,' ', c.last_name) AS customer_name,
        SUM(s.sales_amount) as customer_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c
    ON s.customer_key = c.customer_key
    GROUP BY CONCAT(c.first_name,' ', c.last_name)
)

SELECT
    *,
    SUM(customer_sales) OVER() total_customer_sales,
    ROUND(CAST(customer_sales AS FLOAT)/SUM(customer_sales) OVER()*100,5) AS Percentage
FROM cte_sales
ORDER BY Percentage DESC