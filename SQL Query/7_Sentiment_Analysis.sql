USE olist;


--  Main join structure

CREATE OR REPLACE VIEW vw_sentiment_order_base AS
SELECT
    o.order_id,
    o.customer_unique_id,

    -- time
    o.purchase_ts,
    o.month_start_date,
    o.purchase_year,
    o.purchase_month,
    o.yearmonth,

    -- dimensions
    o.order_type,
    o.main_category_by_revenue,
    o.customer_state,

    -- revenue
    o.total_revenue,
    o.total_price,
    o.total_freight,
    o.item_count,

    -- delivery
    o.days_to_deliver,
    o.is_late,

    -- review
    o.review_score,

    -- sentiment
    s.sentiment_label,
    s.sentiment_proba,
    s.top_topic,
    s.delivery_execution,
    s.product_satisfaction,
    s.fulfillment_failure,
    s.on_time_arrival,
    s.store_advocacy,
    s.review_comment_message

FROM vw_pbi_order_base o
LEFT JOIN sentiment s
    ON o.order_id = s.order_id;
    
SELECT * FROM vw_sentiment_order_base LIMIT 10;

-- Sentiment segment creation
CREATE OR REPLACE VIEW vw_sentiment_order_enriched AS
SELECT
    *,

    CASE
        WHEN sentiment_label = 'positive' AND review_score >= 4 THEN 'Promoters'
        WHEN sentiment_label = 'positive' AND review_score = 3 THEN 'Neutral'
        WHEN sentiment_label = 'negative' AND review_score <= 2 THEN 'Detractors'
        WHEN sentiment_label = 'negative' AND review_score >= 3 THEN 'Silent Risk'
        ELSE 'Unclassified'
    END AS sentiment_segment,

    CASE
        WHEN sentiment_label = 'positive' AND review_score >= 4 THEN 4
        WHEN sentiment_label = 'positive' AND review_score = 3 THEN 3
        WHEN sentiment_label = 'negative' AND review_score <= 2 THEN 2
        WHEN sentiment_label = 'negative' AND review_score >= 3 THEN 1
        ELSE 0
    END AS sentiment_segment_order

FROM vw_sentiment_order_base;

SELECT * FROM vw_sentiment_order_enriched LIMIT 10;

-- Executive KPI view

CREATE OR REPLACE VIEW vw_sentiment_kpi_source AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    COUNT(order_id) AS total_orders,

    ROUND(AVG(review_score),2) AS avg_review_score,

    SUM(CASE WHEN sentiment_label='positive' THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN sentiment_label='negative' THEN 1 ELSE 0 END) AS negative_reviews,

    ROUND(
        100*SUM(CASE WHEN sentiment_label='positive' THEN 1 ELSE 0 END)/COUNT(order_id),
        2
    ) AS positive_sentiment_rate,

    ROUND(
        100*SUM(CASE WHEN sentiment_label='negative' THEN 1 ELSE 0 END)/COUNT(order_id),
        2
    ) AS negative_sentiment_rate

FROM vw_sentiment_order_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type;
    
SELECT * FROM vw_sentiment_kpi_source LIMIT 10;

-- Sentiment Segment Distribution

CREATE OR REPLACE VIEW vw_sentiment_segment_distribution AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    sentiment_segment,
    sentiment_segment_order,

    COUNT(order_id) AS order_count,
    ROUND(AVG(review_score),2) AS avg_review_score

FROM vw_sentiment_order_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    sentiment_segment,
    sentiment_segment_order;
    

SELECT * FROM vw_sentiment_segment_distribution LIMIT 10;

-- Sentiment Trend
CREATE OR REPLACE VIEW vw_sentiment_trend AS
SELECT
    month_start_date,
    yearmonth,
    order_type,

    ROUND(AVG(review_score),2) AS avg_review_score,

    ROUND(
        100*SUM(CASE WHEN sentiment_label='positive' THEN 1 ELSE 0 END)/COUNT(order_id),
        2
    ) AS positive_rate

FROM vw_sentiment_order_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type;
    
SELECT * FROM vw_sentiment_trend LIMIT 10;

-- Negative Sentiment by Topic
CREATE OR REPLACE VIEW vw_negative_topic AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    top_topic,

    COUNT(order_id) AS review_count,

    SUM(CASE WHEN sentiment_label='negative' THEN 1 ELSE 0 END) AS negative_reviews,

    ROUND(
        100*SUM(CASE WHEN sentiment_label='negative' THEN 1 ELSE 0 END)/COUNT(order_id),
        2
    ) AS negative_rate

FROM vw_sentiment_order_enriched
WHERE top_topic IS NOT NULL
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    top_topic;
    
SELECT * FROM vw_negative_topic LIMIT 10;

-- Category Sentiment Analysis

CREATE OR REPLACE VIEW vw_sentiment_category AS
SELECT
    month_start_date,
    yearmonth,
    order_type,
    main_category_by_revenue,

    COUNT(order_id) AS order_count,

    ROUND(AVG(review_score),2) AS avg_review_score,

    ROUND(
        100*SUM(CASE WHEN sentiment_label='negative' THEN 1 ELSE 0 END)/COUNT(order_id),
        2
    ) AS negative_rate

FROM vw_sentiment_order_enriched
GROUP BY
    month_start_date,
    yearmonth,
    order_type,
    main_category_by_revenue;

SELECT * FROM vw_sentiment_category LIMIT 10;

-- Negative review table
CREATE OR REPLACE VIEW vw_top_negative_reviews AS
SELECT
    order_id,
    customer_unique_id,
    customer_state,
    main_category_by_revenue,
    review_score,
    sentiment_label,
    sentiment_proba,
    top_topic,
    review_comment_message
FROM vw_sentiment_order_enriched
WHERE sentiment_label='negative';

    
    