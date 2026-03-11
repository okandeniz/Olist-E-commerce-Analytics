
-- CREATE DATABESE AND TABLES
CREATE DATABASE olist;
USE olist;

CREATE TABLE orders (
    order_id VARCHAR(32) NOT NULL,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NOT NULL,

    PRIMARY KEY (order_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_reviews (
    review_id VARCHAR(32) NOT NULL,
    order_id VARCHAR(32) NOT NULL,
    review_score TINYINT NOT NULL,
    review_comment_title VARCHAR(255) NULL,
    review_comment_message TEXT NULL,
    review_creation_date DATETIME NOT NULL,
    review_answer_timestamp DATETIME NULL,

    PRIMARY KEY (review_id)
);

CREATE TABLE products (
    product_id VARCHAR(32) NOT NULL,
    product_category_name VARCHAR(100) NULL,
    product_name_length INT NULL,
    product_description_length INT NULL,
    product_photos_qty INT NULL,
    product_weight_g DECIMAL(10,2) NULL,
    product_length_cm DECIMAL(10,2) NULL,
    product_height_cm DECIMAL(10,2) NULL,
    product_width_cm DECIMAL(10,2) NULL,

    PRIMARY KEY (product_id)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT NOT NULL,
    geolocation_lat DECIMAL(10,6) NOT NULL,
    geolocation_lng DECIMAL(10,6) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state VARCHAR(5) NOT NULL
);

CREATE TABLE sellers (
    seller_id VARCHAR(32) NOT NULL,
    seller_zip_code_prefix INT NOT NULL,
    seller_city VARCHAR(100) NOT NULL,
    seller_state VARCHAR(5) NOT NULL,

    PRIMARY KEY (seller_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (order_id)
);

CREATE TABLE customers (
    customer_id VARCHAR(32) NOT NULL,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INT NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state VARCHAR(5) NOT NULL,

    PRIMARY KEY (customer_id)
);

CREATE TABLE product_categories (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

SELECT * FROM orders LIMIT 10;

-- LOADING DATA FOR EACH TABLE

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM order_items LIMIT 10;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM order_reviews LIMIT 10;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM products LIMIT 10;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM geolocation LIMIT 10;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM sellers LIMIT 10;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM order_payments LIMIT 10;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM customers LIMIT 10;

LOAD DATA LOCAL INFILE 'C:/Users/okand/Desktop/ecommerce/product_category_name_translation.csv'
INTO TABLE product_categories
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM product_categories LIMIT 10;