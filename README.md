# Olist E-Commerce Analytics

An end-to-end e-commerce analytics project built on the **Olist Brazilian E-Commerce dataset** using **MySQL, Python, Machine Learning, Deep Learning, and Power BI**.

This project covers the full analytics workflow from **data extraction and SQL-based modeling** to **customer analytics, NLP, predictive modeling, recommendation systems, and interactive dashboard reporting**.

---

## Project Overview

The main purpose of this project is to analyze e-commerce operations and customer behavior from multiple perspectives and transform raw transactional data into actionable business insights.

The project includes:

- SQL-based analytical data preparation
- Exploratory Data Analysis (EDA)
- Sentiment Analysis on customer reviews
- RFM-based customer segmentation
- Customer Lifetime Value (CLV) modeling
- A/B Testing for business scenarios
- Churn Prediction
- Recommendation System development
- Power BI dashboard reporting

---

## Live Dashboard

You can access the interactive Power BI dashboard here:

[View Power BI Dashboard](https://app.powerbi.com/groups/me/reports/f8b28b21-6f5b-4b37-95dd-9a98c4c991ba/1b16462317dabaa36b39?experience=power-bi)

---

## Project Structure

```text
Olist-E-Commerce-Analytics/
│
├── Notebook/
│   ├── 01_research.ipynb
│   ├── 02_eda.ipynb
│   ├── 03_sentiment_analysis.ipynb
│   ├── 04_customer_analytics_clv_modeling.ipynb
│   ├── 05_ab_testing.ipynb
│   ├── 06_churn_prediction.ipynb
│   └── 07_recommendation_system.ipynb
│
├── SQL Query/
│   ├── 01_create_database_and_tables.sql
│   ├── 02_create_views_for_ml_and_analysis.sql
│   ├── 03_overview_analysis.sql
│   ├── 04_rfm_analysis.sql
│   ├── 05_clv_analysis.sql
│   ├── 06_churn_analysis.sql
│   ├── 07_sentiment_analysis.sql
│   └── 08_recommendation_analysis.sql
│
├── dashboard/
│   └── dashboard_preview.png
│
├── requirements.txt
└── README.md
