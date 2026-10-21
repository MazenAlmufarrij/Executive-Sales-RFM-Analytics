-- =====================================================================
-- Project: Executive Sales & Customer RFM Intelligence Dashboard
-- Description: RFM Segmentation and Behavioral Scoring Analysis
-- =====================================================================

-- Step 1: Base table aggregating customer-level transactions
WITH Customer_Base AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(sales_amount) AS total_spend
    FROM fact_sales
    GROUP BY customer_id
),

-- Step 2: Calculate raw Recency, Frequency, and Monetary metrics
RFM_Raw AS (
    SELECT 
        customer_id,
        DATEDIFF('day', last_order_date, (SELECT MAX(order_date) FROM fact_sales)) AS recency,
        total_orders AS frequency,
        total_spend AS monetary
    FROM Customer_Base
),

-- Step 3: Compute quintile scores (1-5) using NTILE Window Functions
RFM_Scores AS (
    SELECT 
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM RFM_Raw
)

-- Step 4: Classify customers into actionable behavioral cohorts
SELECT 
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Promising / New'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
        ELSE 'Potential Loyalist'
    END AS segment
FROM RFM_Scores
ORDER BY monetary DESC;
