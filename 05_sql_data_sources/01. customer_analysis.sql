/*

- The customers table stores customer details, including name, contact information, address, assigned sales representative (salesRepEmployeeNumber), and credit limit.
- The employees table contains employee details such as name, extension, email, job title, office assignment (officeCode), and manager (reportsTo).
- The offices table holds office location details, including address, phone, region (territory), and a unique officeCode.
- The orders table tracks customer orders with key dates (order, required, and shipped), status, comments, and associated customer number.
- The orderdetails table records items in each order, including order number, product code, quantity, unit price, and line number.
- The payments table logs customer payments, including customer number, check number, payment date, and amount.
- The products table holds product details such as code, name, category (productLine), scale, vendor, description, stock quantity, cost price, and MSRP.
- The productlines table categorizes products, storing product line ID, descriptions (text and HTML), and an image reference.

*/

SELECT 'customers' AS table_name,
       (SELECT COUNT(*) FROM pragma_table_info('customers')) AS attribute_count,
       (SELECT COUNT(*) FROM customers) AS row_count
 UNION ALL
SELECT 'employees',
       (SELECT COUNT(*) FROM pragma_table_info('employees')),
       (SELECT COUNT(*) FROM employees)
 UNION ALL
SELECT 'offices',
       (SELECT COUNT(*) FROM pragma_table_info('offices')),
       (SELECT COUNT(*) FROM offices)
 UNION ALL
SELECT 'orders',
       (SELECT COUNT(*) FROM pragma_table_info('orders')),
       (SELECT COUNT(*) FROM orders)
 UNION ALL
SELECT 'orderdetails',
       (SELECT COUNT(*) FROM pragma_table_info('orderdetails')),
       (SELECT COUNT(*) FROM orderdetails)
 UNION ALL
SELECT 'payments',
       (SELECT COUNT(*) FROM pragma_table_info('payments')),
       (SELECT COUNT(*) FROM payments)
 UNION ALL
SELECT 'products',
       (SELECT COUNT(*) FROM pragma_table_info('products')),
       (SELECT COUNT(*) FROM products)
 UNION ALL
SELECT 'productlines',
       (SELECT COUNT(*) FROM pragma_table_info('productlines')),
       (SELECT COUNT(*) FROM productlines);



-- This script identifies the top 10 priority products for restocking
-- by calculating the low stock rate (total quantity ordered / quantity in stock)
-- and selecting products that are most in demand relative to their availability.

WITH low_stock_cte AS (
    SELECT p.productCode,
           ROUND(
                   (SELECT SUM(od.quantityOrdered)
                    FROM orderdetails od
                    WHERE p.productCode = od.productCode)
                       / NULLIF(p.quantityInStock, 0), 2) AS low_stock_rate
    FROM products p
)
SELECT *
FROM products
WHERE productCode IN (
    SELECT productCode
    FROM low_stock_cte
    ORDER BY low_stock_rate DESC
    LIMIT 10
);

-- Computing the total profit per customer by aggregating order profits from purchased products.

WITH customer_profit_summary AS (
SELECT o.customerNumber, ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS profit
FROM products p
         JOIN orderdetails od
              ON p.productCode = od.productCode
         JOIN orders o
              ON od.orderNumber = o.orderNumber
GROUP BY o.customerNumber)

SELECT c.contactLastName, c.contactFirstName, c.city, c.country, cps.profit
  FROM customer_profit_summary cps
  JOIN customers c
    ON cps.customerNumber = c.customerNumber
 ORDER BY cps.profit DESC
 LIMIT 5;

WITH customer_profit_summary AS (
    SELECT o.customerNumber,
           ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS profit
    FROM products p
             JOIN orderdetails od ON p.productCode = od.productCode
             JOIN orders o ON od.orderNumber = o.orderNumber
    GROUP BY o.customerNumber
)
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, cps.profit
FROM customer_profit_summary cps
         JOIN customers c ON cps.customerNumber = c.customerNumber
ORDER BY cps.profit
LIMIT 5;

-- This query analyzes customer payment behavior by extracting year-month from payment dates,
-- identifying total customers, new customers, and their contribution to payments over time.

WITH
    payment_with_year_month_table AS (
        SELECT *,
               CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
        FROM payments p
    ),

    customers_by_month_table AS (
        SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
        FROM payment_with_year_month_table p1
        GROUP BY p1.year_month
    ),

    new_customers_by_month_table AS (
        SELECT p1.year_month,
               COUNT(DISTINCT customerNumber) AS number_of_new_customers,
               SUM(p1.amount) AS new_customer_total,
               (SELECT number_of_customers
                FROM customers_by_month_table c
                WHERE c.year_month = p1.year_month) AS number_of_customers,
               (SELECT total
                FROM customers_by_month_table c
                WHERE c.year_month = p1.year_month) AS total
        FROM payment_with_year_month_table p1
        WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                        FROM payment_with_year_month_table p2
                                        WHERE p2.year_month < p1.year_month)
        GROUP BY p1.year_month
    )

SELECT year_month,
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
FROM new_customers_by_month_table;

-- This query calculates the average profit per customer.
-- It first creates a CTE (customer_profit_summary) to compute the total profit for each customer.
-- In the final query, it computes the average profit across all customers.

WITH customer_profit_summary AS (
    SELECT o.customerNumber,
           ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)), 2) AS profit
    FROM products p
             JOIN orderdetails od ON p.productCode = od.productCode
             JOIN orders o ON od.orderNumber = o.orderNumber
    GROUP BY o.customerNumber
)
SELECT ROUND(AVG(cps.profit), 2) AS avg_customer_profit
FROM customer_profit_summary cps;

/*
 Conclusion
 In this project, we analyzed customer engagement and profitability by leveraging SQL queries with Common Table Expressions (CTEs).
 We extracted key metrics such as total customer payments, new customer contributions, and individual customer profits.
 By structuring our queries with CTEs, we improved readability and efficiency, allowing us to break down complex calculations
 into manageable steps. Through this approach, we identified trends in customer behavior and computed the proportion
 of new customers and their impact on revenue over time.

 Our analysis provided insights into customer profitability, helping us determine which customers contributed the
 most and least to the business. Additionally, by identifying new customer trends, we gained a clearer understanding
 of customer acquisition and retention. These findings can help businesses make data-driven decisions to improve
 customer engagement and optimize sales strategies.
 */












