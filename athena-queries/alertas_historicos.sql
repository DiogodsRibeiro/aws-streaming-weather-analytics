CREATE OR REPLACE VIEW gold_db.historical_alerts AS
SELECT 
    time,
    temperature,
    precipitationprobability,
    rainintensity,
    windspeed,
    windgust,
    CASE 
        WHEN precipitationprobability >= 70 THEN 'High Precipitation Risk'
        WHEN rainintensity >= 5 THEN 'Heavy Rain'
        WHEN windgust >= 10 THEN 'Strong Wind Gusts'
        WHEN windspeed >= 10 THEN 'High Wind Speed'
    END as alert_type
FROM gold_db.weather_data
WHERE precipitationprobability >= 70
   OR rainintensity >= 5
   OR windgust >= 10
   OR windspeed >= 10
ORDER BY time DESC;