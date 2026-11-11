/*
Workforce Management Queue Performance Analysis
Author: Derron G. Britton

Business objective:
Analyze how staffing availability, occupancy, demand, wait time,
and forecast accuracy affect long-call abandonment rates.
*/

CREATE database workforce_management; -- created the database
USE workforce_management; -- ensure the correct DB is being used
SELECT * FROM queue_data; -- A quick overview to ensure the table imported correctly
SELECT * FROM staffing; -- A quick overview to ensure the table imported correctly

-- 1.	Which months had the greatest abandonment rate? no year was specified so I have the output showing all three years
SELECT
	year,
    month_name,
    ROUND((aba_calls - short_aba) / offered_calls * 100,1) AS long_aba_pct 
FROM queue_data q
ORDER BY long_aba_pct desc, year
LIMIT 1;

-- 2.	Which months were above the 5 percent abandonment threshold? no year was specified so I have the output showing all three years
SELECT
	year,
    month_name,
    ROUND((aba_calls - short_aba) / offered_calls * 100,1) AS long_aba_pct 
FROM queue_data q
WHERE ROUND((aba_calls - short_aba) / offered_calls * 100,1) > 5
ORDER BY year, long_aba_pct DESC;

-- 3.	What is the average and worst monthly abandonment rate year to date?
SELECT
	ROUND(AVG((aba_calls - short_aba) / offered_calls * 100),1) AS avg_aba_pct,
    ROUND(MIN((aba_calls - short_aba) / offered_calls * 100),1) AS min_aba_pct,
    ROUND(MAX((aba_calls - short_aba) / offered_calls * 100),1) AS max_aba_pct
FROM queue_data q
WHERE year = '2026';

-- 4. Did months with high calls per scheduled hour also have high long abandonment percentages?
SELECT 
	q.year,
    q.month_name,
    q.offered_calls,
    ROUND(SUM(s.lex_scheduled_hours + s.ict_scheduled_hours),1) AS total_scheduled_pr_hours,
    ROUND((aba_calls - short_aba) / offered_calls * 100,1) AS long_aba_pct,
    ROUND(q.offered_calls / SUM(s.lex_scheduled_hours + s.ict_scheduled_hours),1) AS calls_per_scheduled_hours
FROM queue_data q
LEFT JOIN staffing s 
	ON q.year = s.year
    AND q.month_name = s.month
GROUP BY q.year, q.month_name, q.offered_calls, ROUND((aba_calls - short_aba) / offered_calls * 100,1) 
ORDER BY calls_per_scheduled_hours DESC;

-- 5.	Were customers more likely to abandon in months with long waits or lower service level?
SELECT
	year,
    month_name,
    ROUND(AVG(max_queue_wait_time),1) AS maximum_time,
    ROUND(AVG(asa),1) AS avg_speed_of_answer,
    ROUND((aba_calls - short_aba) / offered_calls * 100,1) AS long_aba_pct,
	ROUND(AVG(sl_30_sec) * 100,1) AS avg_sla
FROM queue_data
GROUP BY year, month_name, ROUND((aba_calls - short_aba) / offered_calls * 100,1)
ORDER BY year, maximum_time DESC;

-- 6. Did high absenteeims occur in high-abandonment months?
SELECT
	q.year,
    q.month_name,
	ROUND(SUM(lex_absent_hours + ict_absent_hours) /SUM(lex_scheduled_hours + ict_scheduled_hours) * 100,1)AS absenteeism,
	ROUND((aba_calls - short_aba) / offered_calls * 100,1) AS long_aba_pct
FROM queue_data q
LEFT JOIN staffing s
ON q.month_name = s.month
AND q.year = s.year
GROUP BY q.year, q.month_name,  ROUND((aba_calls - short_aba) / offered_calls * 100,1)
ORDER BY year, absenteeism DESC;

-- 7.	Did under-forecasting appear in high-abandonment months?
SELECT
	q.year,
    q.month_name,
	ROUND((aba_calls - short_aba) / offered_calls * 100,1) AS long_aba_pct,
	ROUND((offered_calls -forecasted_calls ) / forecasted_calls * 100,1) AS forecast_var,
CASE
	WHEN  ROUND((offered_calls -forecasted_calls ) / forecasted_calls * 100,1) < 0 THEN 'under forecast'
	WHEN ROUND((offered_calls -forecasted_calls ) / forecasted_calls * 100,1) > 0 THEN 'above forecast'
    ELSE 'Perfect forecast'
    END AS status
FROM queue_data q
ORDER BY q.year DESC, long_aba_pct DESC;

-- 8.	Which calendar months have the highest average abandonment rate? sub_query used
SELECT 
	month_name,
     ROUND(AVG(long_aba_pct),1) AS avg_long_aba_pct
FROM ( SELECT
	q.year,
	q.month_name,
    (q.aba_calls - q.short_aba) / q.offered_calls * 100 AS long_aba_pct
FROM queue_data q) AS monthly_results
GROUP BY month_name
ORDER BY avg_long_aba_pct DESC;

-- 9.	How do scheduled hours differ between Lex and ICT each month?
SELECT 
	s.month,
    ROUND(SUM(lex_scheduled_hours),0) AS lex_scheduled_hours,
    ROUND(SUM(ict_scheduled_hours),0) AS ict_scheduled_hours,
	ROUND(SUM(ict_scheduled_hours + lex_scheduled_hours),0) AS total_scheduled_hours
FROM staffing s
GROUP BY s.month;

-- 10.	Which four months had the highest absenteeism rate?
SELECT
	s.month,
	ROUND(SUM(lex_absent_hours + ict_absent_hours) /SUM(lex_scheduled_hours + ict_scheduled_hours) * 100,1)AS absenteeism
FROM staffing s
GROUP BY s.month
ORDER BY absenteeism DESC
LIMIT 4;

-- 11.	Which months had the most PTO hours, and did they align with higher abandonment?
SELECT
	q.year,
	q.month_name,
	ROUND(SUM(lex_pto_hours + ict_pto_hours),0) AS total_pto,
    ROUND((q.aba_calls - q.short_aba) / q.offered_calls * 100,1) AS long_aba_pct
FROM queue_data q
LEFT JOIN staffing s 
ON q.year = s.year
AND q.month_name = s.month
GROUP BY q.year, q.month_name, ROUND((q.aba_calls - q.short_aba) / q.offered_calls * 100,1)
ORDER BY q.year, total_pto DESC;

-- 12.	Which months had occupancy above 70 percent?
SELECT
	q.month_name,
	ROUND(AVG(q.inbound_occupancy)*100,1) AS avg_occupancy_pct
FROM queue_data q
GROUP BY q.month_name
HAVING AVG(q.inbound_occupancy) > 0.7
ORDER BY avg_occupancy_pct DESC;

-- 13.	Do high-occupancy months also have above-target abandonment?
SELECT
	q.year,
	q.month_name,
	ROUND(AVG(q.inbound_occupancy)*100,1) AS avg_occupancy_pct,
    ROUND((q.aba_calls - q.short_aba) / q.offered_calls * 100,1) AS long_aba_pct
FROM queue_data q
GROUP BY q.year, q.month_name, ROUND((q.aba_calls - q.short_aba) / q.offered_calls * 100,1)
HAVING AVG(q.inbound_occupancy) > 0.70
ORDER BY q.year, long_aba_pct DESC;

