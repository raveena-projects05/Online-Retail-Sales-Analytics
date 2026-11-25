
/*
ONLINE RETAIL SALES ANALYTICS — ORACLE SQL
Dataset: UCI Online Retail (CSV)
Run in Oracle SQL Developer. One-time setup; drop/recreate objects if rerunning.
Import CSV into ONLINE_RETAIL_STG using SQL Developer Import Data.
Map all 8 source columns as VARCHAR2 initially to avoid import conversion issues.
*/
-- 1. Staging table
CREATE TABLE online_retail_stg (
  InvoiceNo VARCHAR2(30), StockCode VARCHAR2(30), Description VARCHAR2(500),
  Quantity VARCHAR2(40), InvoiceDate VARCHAR2(60), UnitPrice VARCHAR2(40),
  CustomerID VARCHAR2(40), Country VARCHAR2(100)
);

-- Import the CSV into ONLINE_RETAIL_STG using SQL Developer:
-- Right-click table > Import Data; map source columns in the same order.

-- 2. Typed / cleaned table
CREATE TABLE online_retail_clean AS
SELECT
  TRIM(InvoiceNo) AS InvoiceNo,
  TRIM(StockCode) AS StockCode,
  TRIM(Description) AS Description,
  TO_NUMBER(TRIM(Quantity) DEFAULT NULL ON CONVERSION ERROR) AS Quantity,
  COALESCE(
    TO_DATE(TRIM(InvoiceDate) DEFAULT NULL ON CONVERSION ERROR, 'MM/DD/YYYY HH24:MI'),
    TO_DATE(TRIM(InvoiceDate) DEFAULT NULL ON CONVERSION ERROR, 'DD-MON-YY HH.MI.SS.FF AM'),
    TO_DATE(TRIM(InvoiceDate) DEFAULT NULL ON CONVERSION ERROR, 'DD/MM/YYYY HH24:MI')
  ) AS InvoiceDate,
  TO_NUMBER(TRIM(UnitPrice) DEFAULT NULL ON CONVERSION ERROR) AS UnitPrice,
  TO_NUMBER(TRIM(CustomerID) DEFAULT NULL ON CONVERSION ERROR) AS CustomerID,
  TRIM(Country) AS Country
FROM online_retail_stg;

-- 3. Remove exact duplicate records
CREATE TABLE online_retail_dedup AS
SELECT DISTINCT * FROM online_retail_clean;

-- 4. Analytical view: positive-value sales only
CREATE OR REPLACE VIEW vw_retail_sales AS
SELECT InvoiceNo, StockCode, Description, Quantity, InvoiceDate,
       UnitPrice, CustomerID, Country,
       Quantity * UnitPrice AS LineRevenue,
       TO_CHAR(InvoiceDate, 'YYYY-MM') AS YearMonth
FROM online_retail_dedup
WHERE UPPER(InvoiceNo) NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
  AND InvoiceDate IS NOT NULL;

-- 5. KPI summary
SELECT COUNT(*) AS sales_rows,
       COUNT(DISTINCT InvoiceNo) AS total_orders,
       SUM(Quantity) AS units_sold,
       ROUND(SUM(LineRevenue),2) AS total_revenue,
       COUNT(DISTINCT CustomerID) AS identified_customers,
       ROUND(SUM(LineRevenue)/COUNT(DISTINCT InvoiceNo),2) AS avg_order_value
FROM vw_retail_sales;

-- 6. Monthly revenue trend
SELECT YearMonth, ROUND(SUM(LineRevenue),2) AS revenue,
       COUNT(DISTINCT InvoiceNo) AS orders,
       SUM(Quantity) AS units_sold
FROM vw_retail_sales
GROUP BY YearMonth ORDER BY YearMonth;

-- 7. Month-over-month revenue growth
WITH monthly AS (
  SELECT YearMonth, SUM(LineRevenue) revenue
  FROM vw_retail_sales GROUP BY YearMonth
), lagged AS (
  SELECT YearMonth, revenue,
         LAG(revenue) OVER (ORDER BY YearMonth) previous_month_revenue
  FROM monthly
)
SELECT YearMonth, ROUND(revenue,2) revenue,
       ROUND(previous_month_revenue,2) previous_month_revenue,
       ROUND((revenue-previous_month_revenue)/NULLIF(previous_month_revenue,0)*100,2) mom_growth_pct
FROM lagged ORDER BY YearMonth;

-- 8. Country performance and contribution
SELECT Country, ROUND(SUM(LineRevenue),2) revenue,
       COUNT(DISTINCT InvoiceNo) orders,
       ROUND(SUM(LineRevenue)/SUM(SUM(LineRevenue)) OVER ()*100,2) revenue_share_pct
FROM vw_retail_sales
GROUP BY Country ORDER BY revenue DESC;

-- 9. Top 20 products by revenue
SELECT StockCode, MAX(Description) Description,
       ROUND(SUM(LineRevenue),2) revenue,
       SUM(Quantity) units_sold,
       COUNT(DISTINCT InvoiceNo) orders
FROM vw_retail_sales
GROUP BY StockCode ORDER BY revenue DESC FETCH FIRST 20 ROWS ONLY;

-- 10. Top 20 customers by revenue
SELECT CustomerID, ROUND(SUM(LineRevenue),2) revenue,
       COUNT(DISTINCT InvoiceNo) orders,
       SUM(Quantity) units_sold
FROM vw_retail_sales WHERE CustomerID IS NOT NULL
GROUP BY CustomerID ORDER BY revenue DESC FETCH FIRST 20 ROWS ONLY;

-- 11. Average order value and order distribution
WITH orders AS (
  SELECT InvoiceNo, SUM(LineRevenue) order_revenue
  FROM vw_retail_sales GROUP BY InvoiceNo
)
SELECT ROUND(AVG(order_revenue),2) average_order_value,
       ROUND(MEDIAN(order_revenue),2) median_order_value,
       MIN(order_revenue) minimum_order_value,
       MAX(order_revenue) maximum_order_value
FROM orders;

-- 12. Repeat vs one-time customers
WITH customer_orders AS (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) order_count
  FROM vw_retail_sales WHERE CustomerID IS NOT NULL GROUP BY CustomerID
)
SELECT CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END customer_type,
       COUNT(*) customers
FROM customer_orders GROUP BY CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END;

-- 13. Customer RFM-style summary (recency, frequency, monetary)
SELECT CustomerID, MAX(InvoiceDate) last_purchase_date,
       TRUNC(SYSDATE)-TRUNC(MAX(InvoiceDate)) recency_days,
       COUNT(DISTINCT InvoiceNo) frequency,
       ROUND(SUM(LineRevenue),2) monetary_value
FROM vw_retail_sales WHERE CustomerID IS NOT NULL
GROUP BY CustomerID ORDER BY monetary_value DESC;

-- 14. Revenue by weekday
SELECT TO_CHAR(InvoiceDate,'DY','NLS_DATE_LANGUAGE=ENGLISH') weekday,
       ROUND(SUM(LineRevenue),2) revenue,
       COUNT(DISTINCT InvoiceNo) orders
FROM vw_retail_sales
GROUP BY TO_CHAR(InvoiceDate,'D'), TO_CHAR(InvoiceDate,'DY','NLS_DATE_LANGUAGE=ENGLISH')
ORDER BY TO_CHAR(InvoiceDate,'D');

-- 15. Revenue by hour
SELECT TO_CHAR(InvoiceDate,'HH24') invoice_hour,
       ROUND(SUM(LineRevenue),2) revenue,
       COUNT(DISTINCT InvoiceNo) orders
FROM vw_retail_sales GROUP BY TO_CHAR(InvoiceDate,'HH24')
ORDER BY invoice_hour;

-- 16. Cancellation and return counts
SELECT CASE WHEN UPPER(InvoiceNo) LIKE 'C%' THEN 'Cancellation'
            WHEN Quantity < 0 THEN 'Return'
            ELSE 'Other' END transaction_type,
       COUNT(*) row_count
FROM online_retail_dedup
GROUP BY CASE WHEN UPPER(InvoiceNo) LIKE 'C%' THEN 'Cancellation'
              WHEN Quantity < 0 THEN 'Return'
              ELSE 'Other' END;

-- 17. Negative / zero price data quality check
SELECT COUNT(*) non_positive_price_rows
FROM online_retail_dedup WHERE UnitPrice <= 0;

-- 18. Missing-value profile
SELECT COUNT(*) total_rows,
       SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) missing_customer_id,
       SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) missing_description,
       SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) missing_invoice_date
FROM online_retail_dedup;

-- 19. Revenue by country and month
SELECT Country, YearMonth, ROUND(SUM(LineRevenue),2) revenue
FROM vw_retail_sales
GROUP BY Country, YearMonth
ORDER BY Country, YearMonth;

-- 20. Products above average product revenue
WITH product_revenue AS (
  SELECT StockCode, MAX(Description) Description, SUM(LineRevenue) revenue
  FROM vw_retail_sales GROUP BY StockCode
)
SELECT StockCode, Description, ROUND(revenue,2) revenue
FROM product_revenue
WHERE revenue > (SELECT AVG(revenue) FROM product_revenue)
ORDER BY revenue DESC;

-- 21. Top 10 countries by order volume
SELECT Country, COUNT(DISTINCT InvoiceNo) orders
FROM vw_retail_sales GROUP BY Country
ORDER BY orders DESC FETCH FIRST 10 ROWS ONLY;

-- 22. Monthly sales seasonality by year
SELECT TO_CHAR(InvoiceDate,'MM') month_number,
       TO_CHAR(InvoiceDate,'MON','NLS_DATE_LANGUAGE=ENGLISH') month_name,
       ROUND(AVG(month_revenue),2) avg_monthly_revenue
FROM (
  SELECT TO_CHAR(InvoiceDate,'YYYY-MM') year_month,
         TO_CHAR(InvoiceDate,'MM') month_number,
         TO_CHAR(InvoiceDate,'MON','NLS_DATE_LANGUAGE=ENGLISH') month_name,
         SUM(LineRevenue) month_revenue
  FROM vw_retail_sales
  GROUP BY TO_CHAR(InvoiceDate,'YYYY-MM'), TO_CHAR(InvoiceDate,'MM'),
           TO_CHAR(InvoiceDate,'MON','NLS_DATE_LANGUAGE=ENGLISH')
)
GROUP BY month_number, month_name ORDER BY month_number;

-- 23. Final row-count reconciliation
SELECT (SELECT COUNT(*) FROM online_retail_stg) staging_rows,
       (SELECT COUNT(*) FROM online_retail_clean) typed_rows,
       (SELECT COUNT(*) FROM online_retail_dedup) deduplicated_rows,
       (SELECT COUNT(*) FROM vw_retail_sales) valid_sales_rows
FROM dual;
