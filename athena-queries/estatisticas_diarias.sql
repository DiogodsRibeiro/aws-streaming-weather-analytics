CREATE OR REPLACE VIEW gold_db.daily_statistics AS
SELECT 
    CAST(CONCAT(CAST(year AS VARCHAR), '-', 
                LPAD(CAST(month AS VARCHAR), 2, '0'), '-', 
                LPAD(CAST(day AS VARCHAR), 2, '0')) AS DATE) as date,
    ROUND(AVG(temperature), 2) as avg_temp,
    ROUND(MAX(temperature), 2) as max_temp,
    ROUND(MIN(temperature), 2) as min_temp,
    ROUND(AVG(humidity), 2) as avg_humidity,
    ROUND(AVG(windspeed), 2) as avg_wind_speed,
    ROUND(MAX(windgust), 2) as max_wind_gust,
    ROUND(SUM(rainintensity), 2) as total_rain,
    COUNT(*) as measurements
FROM gold_db.weather_data
GROUP BY year, month, day
ORDER BY year DESC, month DESC, day DESC;