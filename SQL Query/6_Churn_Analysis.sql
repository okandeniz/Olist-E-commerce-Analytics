USE olist;

## Churn Analytical Base View

CREATE OR REPLACE VIEW vw_churn_analysis_base AS
SELECT
    c.customer_unique_id,
    c.order_id,
    c.purchase_ts,
    c.month_start_date,
    c.purchase_year,
    c.purchase_month,
    c.yearmonth,
    c.order_type,
    c.customer_state,

    f.total_orders,
    f.total_revenues,
    f.avg_order_value,
    f.total_items,
    f.unique_categories,
    f.avg_items_per_order,
    f.is_repeat_customer,
    f.first_purchase,
    f.last_purchase,
    f.total_reviews,
    f.negative_reviews,
    f.negative_review_ratio,
    f.recency_days,
    f.frequency,
    f.monetary,
    f.expected_purc_1_month,
    f.churn,
    f.chrurn_prob as churn_prob,
    f.churn_pred

FROM vw_customer_latest_order_context c
LEFT JOIN customer_churn_features f
ON c.customer_unique_id = f.customer_unique_id;

SELECT * FROM vw_churn_analysis_base LIMIT 10;

-- Churn Segment Columns
CREATE OR REPLACE VIEW vw_churn_analysis_enriched AS
SELECT
*,

CASE
WHEN churn_prob >= 0.8 THEN 'High Risk'
WHEN churn_prob >= 0.5 THEN 'Medium Risk'
WHEN churn_prob >= 0.2 THEN 'Low Risk'
ELSE 'Safe'
END AS churn_segment,

CASE
WHEN churn_prob >= 0.8 THEN 4
WHEN churn_prob >= 0.5 THEN 3
WHEN churn_prob >= 0.2 THEN 2
ELSE 1
END AS churn_segment_order

FROM vw_churn_analysis_base;

SELECT * FROM vw_churn_analysis_enriched LIMIT 10;


-- KPI'S
CREATE OR REPLACE VIEW vw_churn_kpi_source AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    COUNT(DISTINCT customer_unique_id) AS total_customers,

    SUM(churn) AS churned_customers,

    ROUND(
        100.0 * SUM(churn) /
        COUNT(DISTINCT customer_unique_id),
        2
    ) AS churn_rate,

    ROUND(AVG(churn_prob),4) AS avg_churn_probability

FROM vw_churn_analysis_enriched
GROUP BY
month_start_date,
yearmonth,
order_type;

SELECT * FROM vw_churn_kpi_source LIMIT 10;

-- Churn Segment Distribution
CREATE OR REPLACE VIEW vw_churn_segment_distribution AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    churn_segment,
    churn_segment_order,

    COUNT(DISTINCT customer_unique_id) AS customer_count,
    ROUND(AVG(churn_prob),4) AS avg_churn_probability

FROM vw_churn_analysis_enriched
GROUP BY
month_start_date,
yearmonth,
order_type,
churn_segment,
churn_segment_order;

SELECT * FROM vw_churn_segment_distribution LIMIT 10;

-- Churn by State
CREATE OR REPLACE VIEW vw_churn_by_state AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    customer_state,

    COUNT(DISTINCT customer_unique_id) AS customer_count,
    SUM(churn) AS churned_customers,

    ROUND(
        100.0 * SUM(churn) /
        COUNT(DISTINCT customer_unique_id),
        2
    ) AS churn_rate

FROM vw_churn_analysis_enriched
GROUP BY
month_start_date,
yearmonth,
order_type,
customer_state;

SELECT * FROM vw_churn_by_state LIMIT 10;

-- Churn Drivers
CREATE OR REPLACE VIEW vw_churn_drivers AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    ROUND(AVG(recency_days),2) AS avg_recency,
    ROUND(AVG(frequency),2) AS avg_frequency,
    ROUND(AVG(monetary),2) AS avg_monetary,
    ROUND(AVG(negative_review_ratio),2) AS avg_negative_review_ratio,
    ROUND(AVG(churn_prob),4) AS avg_churn_probability

FROM vw_churn_analysis_enriched
GROUP BY
month_start_date,
yearmonth,
order_type;

SELECT * FROM vw_churn_drivers LIMIT 10;

-- Churn Trend

CREATE OR REPLACE VIEW vw_churn_trend AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    COUNT(DISTINCT customer_unique_id) AS total_customers,
    SUM(churn) AS churned_customers,

    ROUND(
        100.0 * SUM(churn) /
        COUNT(DISTINCT customer_unique_id),
        2
    ) AS churn_rate

FROM vw_churn_analysis_enriched
GROUP BY
month_start_date,
yearmonth,
order_type;

SELECT * FROM vw_churn_trend LIMIT 10;
