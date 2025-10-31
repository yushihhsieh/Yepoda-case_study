-- 1. Create marketing_spend, revenue and external_factors tables

CREATE TABLE marketing_spend(
	date DATE,
	paid_search_spend DECIMAL,
	paid_social_spend DECIMAL,
	display_spend DECIMAL,
	email_spend DECIMAL,
	affiliate_spend DECIMAL,
	tv_spend DECIMAL
);

CREATE TABLE revenue(
	date DATE,
	revenue DECIMAL,
	transactions INTEGER,
	new_customers INTEGER
);

CREATE TABLE external_factors(
	date DATE,
	is_weekend INTEGER,
	is_holiday INTEGER,
	promotion_active INTEGER,
	competitor_index DECIMAL,
	seasonality_index DECIMAL
);

-- 2. Load data from CSV
COPY marketing_spend (date, paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend)
FROM '/Users/yushih/Desktop/Yepoda/marketing_spend.csv' 
DELIMITER ',' 
CSV HEADER;

COPY revenue (date, revenue, transactions, new_customers)
FROM '/Users/yushih/Desktop/Yepoda/revenue.csv' 
DELIMITER ',' 
CSV HEADER;

COPY external_factors (date, is_weekend, is_holiday, promotion_active, competitor_index, seasonality_index)
FROM '/Users/yushih/Desktop/Yepoda/external_factors.csv' 
DELIMITER ',' 
CSV HEADER;