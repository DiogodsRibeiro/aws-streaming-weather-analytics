CREATE OR REPLACE VIEW gold_db.current_conditions AS
SELECT 
    time,
    temperature,
    temperatureapparent,
    humidity,
    precipitationprobability,
    windspeed,
    windgust,
    weathercode,
    visibility
FROM gold_db.weather_data
WHERE year = YEAR(CURRENT_DATE)
  AND month = MONTH(CURRENT_DATE)
  AND day = DAY_OF_MONTH(CURRENT_DATE)
ORDER BY time DESC
LIMIT 1;