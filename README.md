# my-project

Overview

This repository contains SQL scripts for managing and querying a postgre database. The scripts are organized as follows:

    ├── README.md (overview and instructions)
    ├── data/
    │ └── .gitkeep (CSV files)
    ├── sql/
    │ ├── 01_schema_setup.sql
    │ ├── 02_data_quality.sql
    │ ├── 03_exploratory_analysis.sql
    │ ├── 04_channel_performance.sql
    │ ├── 05_advanced_analysis.sql
    │ └── 06_budget_optimization.sql
    ├── results/
    │ └── (CSV exports of key query results)
    └── analysis/
    └── executive_summary.md

1. Database Setup and Loading Data (pgAdmin)
   
    Step 1: Install PostgreSQL and pgAdmin

    Step 2: Create a Database in pgAdmin

    Step 3: Open Query Tool

      Select postgre database.

      Click Tools → Query Tool to open the SQL editor.

    Step 4: Run Schema Script
   
	  Open sql/01_schema_setup.sql in the Query Tool.
	  Copy and paste the following query to create tables
    
          CREATE TABLE marketing_spend(
        	date DATE,
        	paid_search_spend DECIMAL,
        	paid_social_spend DECIMAL,
        	display_spend DECIMAL,
        	email_spend DECIMAL,
        	affiliate_spend DECIMAL,
        	tv_spend DECIMAL);
  
      Click Execute/Run.
  
    Step 5: Load CSV files
   
        COPY marketing_spend (date, paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend)
        FROM '/Users/yushih/Desktop/Yepoda/marketing_spend.csv' 
        DELIMITER ',' 
        CSV HEADER;
    
3. All SQL scripts are written in PostgreSQL dialect.

4. Running SQL Scripts in Sequence

    Step 1: 01_schema_setup.sql -> run first to create tables and load CSVs

    Step 2: 02_data_quality.sql -> run queries in the following sequences:
   
        -- 1.1 Check for missing values
        -- 1.2 Identify any date gaps in the data
        -- 1.3 Find outliner in spend and revenue

    Step 3: 03_exploratory_analysis.sql
   
          -- 1. Create summary statistics for each marketing channel and revenue
          -- 2.1 Analyze temporal patterns
          -- 2.2 Day-of-week patterns
          -- 2.3 Seasonal trends

    Step 4: 04_channel_performance.sql
   
          -- 1. Calculate total spend and total revenue by channel for the entire period
          -- 2. Compute ROAS (Return on Ad Spend) for each channel 
          -- 3. Identify the top and bottom performing channels
          -- 4. Analyze channel performance

    Step 5: 05_advanced_analysis.sql
   
          -- 1. Build a query that shows the correlation between each channel's spend and revenue
          -- 2. Analyze the impact of external factors
          -- 3.1 Compare revenue on days with zero spend vs days with spend for each
          -- 3.2 Calculate the marginal return for different spend levels (quartiles)
          -- 4. Create a cohort analysis showing how marketing efficiency has changed over time

    Step 6: 06_budget_optimization.sql

        -- 1. Identify spending patterns of consistency and variability
        -- 2. Calculate efficiency curves
        -- 3. Provide budget reallocation recommendations

4. Assumptions made

	Since revenue table is in total per day, not broken down by channel, it is not possible to join marketing_spend table on channel level. 
	When compute total revenue by channel, I assume revenue is allocated proportionally to spend share.



