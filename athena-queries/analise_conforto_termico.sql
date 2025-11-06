CREATE OR REPLACE VIEW gold_db.thermal_comfort AS
SELECT 
    time,
    temperature,
    temperatureapparent,
    humidity,
    ROUND(temperatureapparent - temperature, 2) as comfort_index,
    CASE 
        WHEN temperatureapparent - temperature > 5 THEN 'Muito Desconfortável'
        WHEN temperatureapparent - temperature > 2 THEN 'Desconfortável'
        WHEN ABS(temperatureapparent - temperature) <= 2 THEN 'Confortável'
        ELSE 'Fresco'
    END as comfort_level
FROM gold_db.weather_data
ORDER BY time DESC;