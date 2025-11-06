CREATE OR REPLACE VIEW gold_db.extreme_conditions AS
SELECT 
    'Highest Temperature' as condition_type,
    time,
    temperature as value,
    'Celsius' as unit
FROM gold_db.weather_data
WHERE temperature = (SELECT MAX(temperature) FROM gold_db.weather_data)

UNION ALL

SELECT 
    'Lowest Temperature',
    time,
    temperature,
    'Celsius'
FROM gold_db.weather_data
WHERE temperature = (SELECT MIN(temperature) FROM gold_db.weather_data)

UNION ALL

SELECT 
    'Highest Wind Gust',
    time,
    windgust,
    'm/s'
FROM gold_db.weather_data
WHERE windgust = (SELECT MAX(windgust) FROM gold_db.weather_data)

UNION ALL

SELECT 
    'Heaviest Rain',
    time,
    rainintensity,
    'mm/h'
FROM gold_db.weather_data
WHERE rainintensity = (SELECT MAX(rainintensity) FROM gold_db.weather_data);