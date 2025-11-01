-- 1. Build a query that shows the correlation between each channel's spend and revenue
WITH combined AS (
  SELECT m.date,
	m.paid_search_spend,
	m.paid_social_spend,
	m.display_spend,
	m.email_spend,
	m.affiliate_spend,
	m.tv_spend,
    r.revenue
  FROM marketing_spend m
  LEFT JOIN revenue r
	USING(date)
	
-- Computes correlation coefficient between channel spend and revenue
)
  SELECT corr(paid_search_spend, revenue) AS corr_paid_search,
	corr(paid_social_spend, revenue) AS corr_paid_social,
	corr(display_spend, revenue) AS corr_display,
    corr(email_spend, revenue) AS corr_email,
    corr(affiliate_spend, revenue) AS corr_affiliate,
    corr(tv_spend, revenue) AS corr_tv
  FROM combined;


-- 2. Analyze the impact of external factors
WITH combined AS (
  SELECT r.date,
        r.revenue,
        r.transactions,
        r.new_customers,
        e.is_weekend,
        e.is_holiday,
        e.promotion_active,
        e.seasonality_index
  FROM revenue r
  LEFT JOIN external_factors e
	USING(date)
	
), factors_analysis AS (
  SELECT
    -- Revenue lift during holidays
	-- Compare average revenue on holiday vs non-holiday dates.
	AVG(CASE WHEN is_holiday = 1 THEN revenue ELSE NULL END) AS avg_revenue_holiday,
    AVG(CASE WHEN is_holiday = 0 THEN revenue ELSE NULL END) AS avg_revenue_non_holiday,
    AVG(CASE WHEN is_holiday = 1 THEN revenue ELSE NULL END) - 
    AVG(CASE WHEN is_holiday = 0 THEN revenue ELSE NULL END) AS revenue_lift_holiday,

    -- Revenue lift during promotions
	-- Compare average revenue on promotion-active days vs non-promo days.
    AVG(CASE WHEN promotion_active = 1 THEN revenue ELSE NULL END) AS avg_revenue_promo,
    AVG(CASE WHEN promotion_active = 0 THEN revenue ELSE NULL END) AS avg_revenue_no_promo,
    AVG(CASE WHEN promotion_active = 1 THEN revenue ELSE NULL END) - 
    AVG(CASE WHEN promotion_active = 0 THEN revenue ELSE NULL END) AS revenue_lift_promo,

    -- Impact of weekend vs weekday
	-- Compare revenue on weekends vs weekdays
    AVG(CASE WHEN is_weekend = 1 THEN revenue ELSE NULL END) AS avg_revenue_weekend,
    AVG(CASE WHEN is_weekend = 0 THEN revenue ELSE NULL END) AS avg_revenue_weekday,
    AVG(CASE WHEN is_weekend = 1 THEN revenue ELSE NULL END) - 
    AVG(CASE WHEN is_weekend = 0 THEN revenue ELSE NULL END) AS revenue_diff_weekend_vs_weekday,

    -- Effect of seasonality
	-- Compute correlation between seasonality_index and revenue
    CORR(revenue, seasonality_index) AS seasonality_impact_corr
  FROM combined

)
  SELECT revenue_lift_holiday,
	revenue_lift_promo,
	revenue_diff_weekend_vs_weekday,
	seasonality_impact_corr
  FROM factors_analysis;


-- 3. Calculate incrementality
-- 3.1 Compare revenue on days with zero spend vs days with spend for each
WITH daily_data AS (
  SELECT r.date,
	r.revenue,
	r.transactions,
	r.new_customers,
	ms.paid_search_spend,
	ms.paid_social_spend,
	ms.display_spend,
	ms.email_spend,
	ms.affiliate_spend,
	ms.tv_spend
  FROM revenue r
  LEFT JOIN marketing_spend ms 
	USING(date)

-- Unpivot channels
), unpivoted AS (
  SELECT date,
	revenue,
	col_name AS channel,
	value AS spend
  FROM daily_data
	CROSS JOIN LATERAL 
        UNNEST(ARRAY['paid_search','paid_social','display','email','affiliate','tv'],
			ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]
		) AS u(col_name, value)

), zero_vs_nonzero AS (
  SELECT channel,
	AVG(CASE WHEN spend = 0 THEN revenue END) AS avg_revenue_zero_spend,
	AVG(CASE WHEN spend > 0 THEN revenue END) AS avg_revenue_with_spend
  FROM unpivoted
  GROUP BY 1
)

  SELECT * 
  FROM zero_vs_nonzero
  ORDER BY channel;


-- 3.2 Calculate the marginal return for different spend levels (quartiles)
WITH daily_data AS (
  SELECT r.date,
	r.revenue,
	r.transactions,
	r.new_customers,
	ms.paid_search_spend,
	ms.paid_social_spend,
	ms.display_spend,
	ms.email_spend,
	ms.affiliate_spend,
	ms.tv_spend
  FROM revenue r
  LEFT JOIN marketing_spend ms 
	USING(date)

-- Unpivot channels
), unpivoted AS (
  SELECT date,
	revenue,
	col_name AS channel,
	value AS spend
  FROM daily_data
	CROSS JOIN LATERAL 
        UNNEST(ARRAY['paid_search','paid_social','display','email','affiliate','tv'],
			ARRAY[paid_search_spend, paid_social_spend, display_spend, email_spend, affiliate_spend, tv_spend]
		) AS u(col_name, value)

-- Quartiles per channel
-- Use NTILE() window function to divide each channel’s spend into quartiles	
), quartiles AS (
  SELECT *,
	NTILE(4) OVER (PARTITION BY channel ORDER BY spend) AS spend_quartile
  FROM unpivoted

-- Compute marginal_return: revenue per unit of spend	
), marginal_return AS (
  SELECT channel,
	spend_quartile,
	AVG(spend) AS avg_spend,
	AVG(revenue) AS avg_revenue,
	AVG(revenue)/NULLIF(AVG(spend),0) AS marginal_return
  FROM quartiles
  GROUP BY 1, 2
  ORDER BY 1, 2

)
  SELECT channel,
	spend_quartile,
	marginal_return
  FROM marginal_return;


-- 4. Create a cohort analysis showing how marketing efficiency has changed over time
WITH combined AS (
  SELECT m.date,
	r.revenue,
	m.paid_search_spend,
	m.paid_social_spend,
	m.display_spend,
	m.email_spend,
	m.affiliate_spend,
	m.tv_spend
  FROM marketing_spend m
  LEFT JOIN revenue r
	USING(date)

-- Create monthly cohorts: sum spend per channel and revenue per month
), monthly_cohorts AS (
  SELECT DATE_TRUNC('month', date) AS cohort_month,
	SUM(paid_search_spend) AS total_paid_search_spend,
	SUM(paid_social_spend) AS total_paid_social_spend,
	SUM(display_spend) AS total_display_spend,
	SUM(email_spend) AS total_email_spend,
	SUM(affiliate_spend) AS total_affiliate_spend,
	SUM(tv_spend) AS total_tv_spend,
	SUM(revenue) AS total_revenue
  FROM combined
  GROUP BY 1
  ORDER BY 1

-- Calculate Revenue per channel spend (ROAS)	
)
  SELECT cohort_month,
	CASE WHEN total_paid_search_spend = 0 THEN NULL ELSE total_revenue / total_paid_search_spend END AS roas_paid_search,
    CASE WHEN total_paid_social_spend = 0 THEN NULL ELSE total_revenue / total_paid_social_spend END AS roas_paid_social,
    CASE WHEN total_display_spend = 0 THEN NULL ELSE total_revenue / total_display_spend END AS roas_display,
    CASE WHEN total_email_spend = 0 THEN NULL ELSE total_revenue / total_email_spend END AS roas_email,
    CASE WHEN total_affiliate_spend = 0 THEN NULL ELSE total_revenue / total_affiliate_spend END AS roas_affiliate,
    CASE WHEN total_tv_spend = 0 THEN NULL ELSE total_revenue / total_tv_spend END AS roas_tv,

    -- Add overall marketing efficiency
    total_revenue / NULLIF(total_paid_search_spend + total_paid_social_spend + total_display_spend + total_email_spend + total_affiliate_spend + total_tv_spend, 0) AS overall_roas
  FROM monthly_cohorts
  ORDER BY cohort_month;
