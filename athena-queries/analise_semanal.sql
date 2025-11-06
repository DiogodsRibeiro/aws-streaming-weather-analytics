CREATE OR REPLACE VIEW gold_db.weekly_trends AS
SELECT 
    DATE_TRUNC('week', 
        CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                    LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                    LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE)
    ) as week_start,
    ROUND(AVG(temperature), 2) as avg_temp,
    ROUND(AVG(humidity), 2) as avg_humidity,
    ROUND(AVG(windspeed), 2) as avg_wind,
    ROUND(SUM(rainintensity), 2) as total_rain,
    COUNT(*) as measurements
FROM gold_db.weather_data
GROUP BY DATE_TRUNC('week', 
    CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE))
ORDER BY week_start DESC;