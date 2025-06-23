drop table if exists dim_date;

CREATE TABLE dim_date (
	`dim_date_id` INT PRIMARY KEY AUTO_INCREMENT,
    `date` DATE,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(15),
    week INT,
    weekday INT,
    weekday_name VARCHAR(15),
    is_weekend BOOLEAN
);

SET SESSION cte_max_recursion_depth = 20000;


INSERT INTO dim_date (
    `date`,
    `year`,
    `quarter`,
    `month`,
    `month_name`,
    `week`,
    `weekday`,
    `weekday_name`,
    `is_weekend`
)
WITH RECURSIVE date_series AS (
  -- 1. Anchor Member: This is the starting date of your series.
  SELECT CAST('2000-01-01' AS DATE) AS generated_date

  UNION ALL

  -- 2. Recursive Member: This part adds 1 day to the previous date.
  SELECT DATE_ADD(generated_date, INTERVAL 1 DAY)
  FROM date_series
  -- 3. Terminator: The recursion stops when the date reaches the end date.
  WHERE generated_date < '2024-04-30'
)
-- 4. Final Projection: Format the generated dates and insert them into the table.
SELECT
    generated_date AS `date`,
    YEAR(generated_date) AS `year`,
    QUARTER(generated_date) AS `quarter`,
    MONTH(generated_date) AS `month`,
    MONTHNAME(generated_date) AS `month_name`,
    WEEK(generated_date, 3) AS `week`, -- Mode 3: Monday is the first day of the week, 1-53
    WEEKDAY(generated_date) + 1 AS `weekday`, -- MySQL's WEEKDAY() is 0=Mon..6=Sun. We add 1 to make it 1-7.
    DAYNAME(generated_date) AS `weekday_name`,
    -- In MySQL, WEEKDAY() returns 5 for Saturday and 6 for Sunday.
    CASE WHEN WEEKDAY(generated_date) >= 5 THEN TRUE ELSE FALSE END AS `is_weekend`
FROM date_series;
