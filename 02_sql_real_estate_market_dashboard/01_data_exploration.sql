-- Проект модуля 1. Первичное исследование данных real_estate.
-- Запускайте запросы по одному блоку в DBeaver: так проще читать результаты.


-- 1. Размер таблиц.
SELECT 'advertisement' AS table_name, COUNT(*) AS rows_cnt
FROM real_estate.advertisement
UNION ALL
SELECT 'flats', COUNT(*)
FROM real_estate.flats
UNION ALL
SELECT 'city', COUNT(*)
FROM real_estate.city
UNION ALL
SELECT 'type', COUNT(*)
FROM real_estate.type;


-- 2. Явные дубликаты по первичным ключам.
-- Если запрос возвращает строки, значит один и тот же id встречается несколько раз.
SELECT id, COUNT(*) AS duplicate_cnt
FROM real_estate.advertisement
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, COUNT(*) AS duplicate_cnt
FROM real_estate.flats
GROUP BY id
HAVING COUNT(*) > 1;

SELECT city_id, COUNT(*) AS duplicate_cnt
FROM real_estate.city
GROUP BY city_id
HAVING COUNT(*) > 1;

SELECT type_id, COUNT(*) AS duplicate_cnt
FROM real_estate.type
GROUP BY type_id
HAVING COUNT(*) > 1;


-- 3. Проверка связей между таблицами.
-- Квартиры без объявления.
SELECT f.id
FROM real_estate.flats AS f
LEFT JOIN real_estate.advertisement AS a ON a.id = f.id
WHERE a.id IS NULL;

-- Объявления без квартиры.
SELECT a.id
FROM real_estate.advertisement AS a
LEFT JOIN real_estate.flats AS f ON f.id = a.id
WHERE f.id IS NULL;

-- Квартиры с city_id, которого нет в справочнике city.
SELECT f.city_id, COUNT(*) AS rows_cnt
FROM real_estate.flats AS f
LEFT JOIN real_estate.city AS c ON c.city_id = f.city_id
WHERE c.city_id IS NULL
GROUP BY f.city_id;

-- Квартиры с type_id, которого нет в справочнике type.
SELECT f.type_id, COUNT(*) AS rows_cnt
FROM real_estate.flats AS f
LEFT JOIN real_estate.type AS t ON t.type_id = f.type_id
WHERE t.type_id IS NULL
GROUP BY f.type_id;


-- 4. Неявные дубликаты в справочниках.
-- LOWER + TRIM помогает поймать отличия только в регистре или лишних пробелах.
SELECT LOWER(TRIM(city)) AS city_normalized,
       COUNT(*) AS duplicate_cnt,
       STRING_AGG(city, ', ' ORDER BY city) AS source_values
FROM real_estate.city
GROUP BY LOWER(TRIM(city))
HAVING COUNT(*) > 1;

SELECT LOWER(TRIM(type)) AS type_normalized,
       COUNT(*) AS duplicate_cnt,
       STRING_AGG(type, ', ' ORDER BY type) AS source_values
FROM real_estate.type
GROUP BY LOWER(TRIM(type))
HAVING COUNT(*) > 1;


-- 5. Уникальные значения категориальных признаков.
SELECT type_id, type
FROM real_estate.type
ORDER BY type;

SELECT city_id, city
FROM real_estate.city
ORDER BY city;

SELECT is_apartment, COUNT(*) AS rows_cnt
FROM real_estate.flats
GROUP BY is_apartment
ORDER BY is_apartment;

SELECT open_plan, COUNT(*) AS rows_cnt
FROM real_estate.flats
GROUP BY open_plan
ORDER BY open_plan;


-- 6. Пропуски в advertisement.
SELECT COUNT(*) AS rows_total,
       COUNT(*) FILTER (WHERE id IS NULL) AS id_nulls,
       COUNT(*) FILTER (WHERE first_day_exposition IS NULL) AS first_day_exposition_nulls,
       COUNT(*) FILTER (WHERE days_exposition IS NULL) AS days_exposition_nulls,
       COUNT(*) FILTER (WHERE last_price IS NULL) AS last_price_nulls
FROM real_estate.advertisement;


-- 7. Пропуски в flats.
SELECT COUNT(*) AS rows_total,
       COUNT(*) FILTER (WHERE id IS NULL) AS id_nulls,
       COUNT(*) FILTER (WHERE city_id IS NULL) AS city_id_nulls,
       COUNT(*) FILTER (WHERE type_id IS NULL) AS type_id_nulls,
       COUNT(*) FILTER (WHERE total_area IS NULL) AS total_area_nulls,
       COUNT(*) FILTER (WHERE rooms IS NULL) AS rooms_nulls,
       COUNT(*) FILTER (WHERE ceiling_height IS NULL) AS ceiling_height_nulls,
       COUNT(*) FILTER (WHERE floors_total IS NULL) AS floors_total_nulls,
       COUNT(*) FILTER (WHERE living_area IS NULL) AS living_area_nulls,
       COUNT(*) FILTER (WHERE floor IS NULL) AS floor_nulls,
       COUNT(*) FILTER (WHERE is_apartment IS NULL) AS is_apartment_nulls,
       COUNT(*) FILTER (WHERE open_plan IS NULL) AS open_plan_nulls,
       COUNT(*) FILTER (WHERE kitchen_area IS NULL) AS kitchen_area_nulls,
       COUNT(*) FILTER (WHERE balcony IS NULL) AS balcony_nulls,
       COUNT(*) FILTER (WHERE airports_nearest IS NULL) AS airports_nearest_nulls,
       COUNT(*) FILTER (WHERE parks_around3000 IS NULL) AS parks_around3000_nulls,
       COUNT(*) FILTER (WHERE ponds_around3000 IS NULL) AS ponds_around3000_nulls
FROM real_estate.flats;


-- 8. Разброс количественных значений advertisement.
SELECT MIN(first_day_exposition) AS first_date,
       MAX(first_day_exposition) AS last_date,
       MIN(days_exposition) AS min_days_exposition,
       MAX(days_exposition) AS max_days_exposition,
       ROUND(AVG(days_exposition)::numeric, 2) AS avg_days_exposition,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY days_exposition) AS median_days_exposition,
       MIN(last_price) AS min_last_price,
       MAX(last_price) AS max_last_price,
       ROUND(AVG(last_price)::numeric, 2) AS avg_last_price
FROM real_estate.advertisement;


-- 9. Разброс количественных значений flats.
SELECT MIN(total_area) AS min_total_area,
       MAX(total_area) AS max_total_area,
       ROUND(AVG(total_area)::numeric, 2) AS avg_total_area,
       MIN(rooms) AS min_rooms,
       MAX(rooms) AS max_rooms,
       MIN(ceiling_height) AS min_ceiling_height,
       MAX(ceiling_height) AS max_ceiling_height,
       MIN(floors_total) AS min_floors_total,
       MAX(floors_total) AS max_floors_total,
       MIN(living_area) AS min_living_area,
       MAX(living_area) AS max_living_area,
       MIN(floor) AS min_floor,
       MAX(floor) AS max_floor,
       MIN(kitchen_area) AS min_kitchen_area,
       MAX(kitchen_area) AS max_kitchen_area,
       MIN(balcony) AS min_balcony,
       MAX(balcony) AS max_balcony,
       MIN(airports_nearest) AS min_airports_nearest,
       MAX(airports_nearest) AS max_airports_nearest,
       MIN(parks_around3000) AS min_parks_around3000,
       MAX(parks_around3000) AS max_parks_around3000,
       MIN(ponds_around3000) AS min_ponds_around3000,
       MAX(ponds_around3000) AS max_ponds_around3000
FROM real_estate.flats;


-- 10. Подозрительные значения в advertisement.
SELECT *
FROM real_estate.advertisement
WHERE first_day_exposition > CURRENT_DATE
   OR days_exposition < 0
   OR last_price <= 0
ORDER BY id;


-- 11. Подозрительные значения в flats.
-- Пороги можно уточнить после просмотра min/max из блока выше.
SELECT *
FROM real_estate.flats
WHERE total_area <= 0
   OR rooms < 0
   OR ceiling_height <= 0
   OR floors_total <= 0
   OR living_area <= 0
   OR floor <= 0
   OR floor > floors_total
   OR kitchen_area <= 0
   OR living_area > total_area
   OR kitchen_area > total_area
   OR living_area + kitchen_area > total_area
   OR balcony < 0
   OR airports_nearest < 0
   OR parks_around3000 < 0
   OR ponds_around3000 < 0
   OR is_apartment NOT IN (0, 1)
   OR open_plan NOT IN (0, 1)
ORDER BY id;


-- 12. Более мягкий список потенциальных аномалий для ручной проверки.
-- Эти значения не обязательно ошибки, но их стоит посмотреть отдельно.
SELECT f.id,
       c.city,
       t.type,
       a.first_day_exposition,
       a.days_exposition,
       a.last_price,
       f.total_area,
       f.rooms,
       f.ceiling_height,
       f.floors_total,
       f.living_area,
       f.floor,
       f.kitchen_area,
       f.balcony,
       f.airports_nearest
FROM real_estate.flats AS f
JOIN real_estate.advertisement AS a ON a.id = f.id
LEFT JOIN real_estate.city AS c ON c.city_id = f.city_id
LEFT JOIN real_estate.type AS t ON t.type_id = f.type_id
WHERE a.days_exposition > 1500
   OR a.last_price < 100000
   OR a.last_price > 100000000
   OR f.total_area < 10
   OR f.total_area > 500
   OR f.rooms > 10
   OR f.ceiling_height < 2
   OR f.ceiling_height > 5
   OR f.floors_total > 40
   OR f.balcony > 5
   OR f.airports_nearest > 100000
ORDER BY a.last_price DESC, f.total_area DESC;

-- 13. Распределение объявлений по типам населённых пунктов:
SELECT t.type,
	   COUNT(DISTINCT c.city_id) AS cities_count,
       COUNT(f.id) AS ads_count
FROM real_estate.type AS t
LEFT JOIN real_estate.flats AS f ON t.type_id = f.type_id
LEFT JOIN real_estate.city AS c ON f.city_id = c.city_id
GROUP BY t.type
ORDER BY cities_count DESC;

-- 14. Процент объявлений, которые сняли с публикации:
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE days_exposition IS NOT NULL) / COUNT(*), 2) AS removed_advertisements_percent
FROM real_estate.advertisement;

-- 15. Процент объявлений о продаже квартир в Санкт-Петербурге
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE c.city = 'Санкт-Петербург') / COUNT(*), 2) AS spb_advertisements_percent
FROM real_estate.advertisement AS a
LEFT JOIN real_estate.flats AS f ON a.id = f.id
LEFT JOIN real_estate.city AS c ON f.city_id = c.city_id;

-- 16. Основные статистические показатели стоимости одного квадратного метра:
WITH square_meter_prices AS (
    SELECT a.last_price / f.total_area AS square_meter_price
    FROM real_estate.advertisement AS a
    JOIN real_estate.flats AS f ON a.id = f.id
    WHERE a.last_price IS NOT NULL
      AND f.total_area IS NOT NULL
      AND f.total_area > 0
)
SELECT ROUND(MIN(square_meter_price)::numeric, 2) AS min_square_meter_price,
       ROUND(MAX(square_meter_price)::numeric, 2) AS max_square_meter_price,
       ROUND(AVG(square_meter_price)::numeric, 2) AS avg_square_meter_price,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY square_meter_price)::numeric, 2) AS median_square_meter_price
FROM square_meter_prices;

-- 17. Статистические показатели по количественным данным:
-- total_area — общая площадь, rooms — количество комнат, balcony — количество балконов,
-- ceiling_height — высота потолков, floor — этаж квартиры.
SELECT 'total_area' AS metric,
       ROUND(MIN(total_area)::numeric, 2) AS min_value,
       ROUND(MAX(total_area)::numeric, 2) AS max_value,
       ROUND(AVG(total_area)::numeric, 2) AS avg_value,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_area)::numeric, 2) AS median_value,
       ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area)::numeric, 2) AS percentile_99
FROM real_estate.flats
WHERE total_area IS NOT NULL

UNION ALL

SELECT 'rooms' AS metric,
       ROUND(MIN(rooms)::numeric, 2) AS min_value,
       ROUND(MAX(rooms)::numeric, 2) AS max_value,
       ROUND(AVG(rooms)::numeric, 2) AS avg_value,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rooms)::numeric, 2) AS median_value,
       ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY rooms)::numeric, 2) AS percentile_99
FROM real_estate.flats
WHERE rooms IS NOT NULL

UNION ALL

SELECT 'balcony' AS metric,
       ROUND(MIN(balcony)::numeric, 2) AS min_value,
       ROUND(MAX(balcony)::numeric, 2) AS max_value,
       ROUND(AVG(balcony)::numeric, 2) AS avg_value,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balcony)::numeric, 2) AS median_value,
       ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY balcony)::numeric, 2) AS percentile_99
FROM real_estate.flats
WHERE balcony IS NOT NULL

UNION ALL

SELECT 'ceiling_height' AS metric,
       ROUND(MIN(ceiling_height)::numeric, 2) AS min_value,
       ROUND(MAX(ceiling_height)::numeric, 2) AS max_value,
       ROUND(AVG(ceiling_height)::numeric, 2) AS avg_value,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ceiling_height)::numeric, 2) AS median_value,
       ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height)::numeric, 2) AS percentile_99
FROM real_estate.flats
WHERE ceiling_height IS NOT NULL

UNION ALL

SELECT 'floor' AS metric,
       ROUND(MIN(floor)::numeric, 2) AS min_value,
       ROUND(MAX(floor)::numeric, 2) AS max_value,
       ROUND(AVG(floor)::numeric, 2) AS avg_value,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY floor)::numeric, 2) AS median_value,
       ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY floor)::numeric, 2) AS percentile_99
FROM real_estate.flats
WHERE floor IS NOT NULL;