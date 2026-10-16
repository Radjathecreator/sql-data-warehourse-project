/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */
WITH yearly_product_sales AS (
    SELECT
        YEAR(s.order_date) AS order_year,
        p.product_name,
        SUM(s.sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
    ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY (YEAR(s.order_date)), p.product_name
 )
, calculated_performance AS
(
    SELECT
        order_year,
        product_name,
        total_sales,
        AVG(total_sales) OVER(PARTITION BY product_name) AS average_sales,
        total_sales - AVG(total_sales) OVER(PARTITION BY product_name) as different_avg,
        CASE 
            WHEN total_sales - AVG(total_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Average'
            WHEN total_sales - AVG(total_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Average'
            Else 'Average'
        END AS avg_change,
        LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) AS previous_year_sales,
        total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) AS different_sales,
        CASE 
            WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) < 0 THEN 'Decreasing'
            WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_year ASC) > 0 THEN 'Increasing'
            Else 'No Change'
        END AS change_sales_peryear
    FROM yearly_product_sales
)
SELECT TOP 10 *
FROM calculated_performance
WHERE change_sales_peryear = 'Increasing'
ORDER BY different_sales DESC

-- Find a customer who order more than average sales in their country

WITH sales_by_customer AS (
    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name, -- Added space
        c.country,
        FORMAT(s.order_date, 'yyyy-MM') AS sales_month,           -- Includes year so months don't mix
        SUM(s.sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key
    WHERE s.order_date IS NOT NULL
    GROUP BY 
        CONCAT(c.first_name, ' ', c.last_name), 
        c.country, 
        FORMAT(s.order_date, 'yyyy-MM')
), 
sales_calculation AS (
    SELECT 
        customer_name,
        country,
        sales_month,
        total_sales,
        -- Average monthly sales for this specific customer
        AVG(total_sales) OVER(PARTITION BY country) AS country_avg_sales,
        -- Difference between this month and the customer's average
        total_sales - AVG(total_sales) OVER(PARTITION BY customer_name) AS different_sales,
        CASE 
            WHEN total_sales - AVG(total_sales) OVER(PARTITION BY country) > 0 THEN 'Above Average'
            WHEN total_sales - AVG(total_sales) OVER(PARTITION BY country) < 0 THEN 'Below Average'
            ELSE 'Average'
        END AS sales_description
    FROM sales_by_customer
)
SELECT TOP 10 *
FROM sales_calculation
WHERE sales_description = 'Above Average'
ORDER BY different_sales DESC;