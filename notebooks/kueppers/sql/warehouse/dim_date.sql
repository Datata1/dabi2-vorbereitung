-- Benutzerdefinierte Variablen setzen
SET @start_date = '2000-01-01';
SET @end_date = '2024-04-30';
SET cte_max_recursion_depth = 10000;

-- Temporäre Zählhilfe: Liste mit Tagen)
insert into ds420kupe1234_dwh.dim_date (`date`, year, quarter, month, month_name, week, weekday, weekday_name, is_weekend)
WITH RECURSIVE datum_liste AS (
  SELECT @start_date AS datum
  UNION ALL
  SELECT DATE_ADD(datum, INTERVAL 1 DAY)
  FROM datum_liste
  WHERE datum < @end_date
)
SELECT
    datum,
    YEAR(datum) AS jahr,
    QUARTER(datum) AS quartal,
    MONTH(datum) AS monat,
    MONTHNAME(datum) AS monat_name,
    WEEK(datum, 3) AS woche,
    WEEKDAY(datum) + 1 AS wochentag,
    DAYNAME(datum) AS wochentag_name,
    CASE WHEN WEEKDAY(datum) IN (5,6) THEN TRUE ELSE FALSE END AS ist_wochenende
FROM datum_liste;