-- 1. Drop and recreate table
DROP TABLE IF EXISTS revenue;

CREATE TABLE revenue(
	date DATE,
	revenue DECIMAL,
	transactions INTEGER,
	new_customers INTEGER
);

-- 2. Load from CSV
COPY revenue (date, revenue, transactions, new_customers)
FROM '/Users/yushih/Desktop/revenue.csv' 
DELIMITER ',' 
CSV HEADER;