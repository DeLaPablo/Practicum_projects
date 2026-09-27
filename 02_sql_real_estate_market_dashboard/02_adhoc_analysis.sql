/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 *
 * Автор: Павлович Арсений
 * Дата: 22.05.2026
*/


-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:

WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
prepared_ads AS (
    SELECT
        a.id,
        CASE
            WHEN c.city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
            ELSE 'Ленинградская область'
        END AS region,
        CASE
            WHEN a.days_exposition IS NULL THEN 'non category'
            WHEN a.days_exposition BETWEEN 1 AND 30 THEN '1-30 days'
            WHEN a.days_exposition BETWEEN 31 AND 90 THEN '31-90 days'
            WHEN a.days_exposition BETWEEN 91 AND 180 THEN '91-180 days'
            WHEN a.days_exposition >= 181 THEN '181+ days'
        END AS activity_category,
        CASE
            WHEN a.days_exposition IS NULL THEN 5
            WHEN a.days_exposition BETWEEN 1 AND 30 THEN 1
            WHEN a.days_exposition BETWEEN 31 AND 90 THEN 2
            WHEN a.days_exposition BETWEEN 91 AND 180 THEN 3
            WHEN a.days_exposition >= 181 THEN 4
        END AS activity_category_order,
        a.days_exposition,
        a.last_price,
        f.total_area,
        f.rooms,
        f.balcony,
        f.ceiling_height,
        f.floor,
        f.floors_total,
        f.living_area,
        f.kitchen_area
    FROM real_estate.advertisement AS a
    JOIN real_estate.flats AS f ON a.id = f.id
    JOIN real_estate.city AS c ON f.city_id = c.city_id
    JOIN real_estate.type AS t ON f.type_id = t.type_id
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND t.type = 'город'
      AND a.first_day_exposition >= DATE '2015-01-01'
      AND a.first_day_exposition < DATE '2019-01-01'
      AND a.last_price IS NOT NULL
      AND f.total_area > 0
),
aggregated_ads AS (
    SELECT
        region,
        activity_category,
        activity_category_order,
        COUNT(*) AS ads_count,
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY region), 2) AS region_ads_share,
        ROUND(AVG(days_exposition)::numeric, 2) AS avg_days_exposition,
        ROUND(AVG(last_price / total_area)::numeric, 2) AS avg_square_meter_price,
        ROUND(AVG(total_area)::numeric, 2) AS avg_total_area,
        ROUND(AVG(living_area)::numeric, 2) AS avg_living_area,
        ROUND(AVG(kitchen_area)::numeric, 2) AS avg_kitchen_area,
-- Заменил на медианы:
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS median_rooms,
        PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS median_balcony,
        ROUND(AVG(ceiling_height)::numeric, 2) AS avg_ceiling_height,
        ROUND(AVG(floor)::numeric, 2) AS avg_floor,
        ROUND(AVG(floors_total)::numeric, 2) AS avg_floors_total
    FROM prepared_ads
    GROUP BY region, activity_category, activity_category_order
)
SELECT
    region,
    activity_category,
    ads_count,
    region_ads_share,
    avg_days_exposition,
    avg_square_meter_price,
    avg_total_area,
    avg_living_area,
    avg_kitchen_area,
    median_rooms,
    median_balcony,
    avg_ceiling_height,
    avg_floor,
    avg_floors_total
FROM aggregated_ads
ORDER BY region, activity_category_order;


-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:

WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
prepared_ads AS (
    SELECT
        a.id,
        a.first_day_exposition,
        (a.first_day_exposition + (a.days_exposition * INTERVAL '1 day'))::date AS last_day_exposition,
        EXTRACT(MONTH FROM a.first_day_exposition)::int AS publication_month,
        EXTRACT(MONTH FROM a.first_day_exposition + (a.days_exposition * INTERVAL '1 day'))::int AS removal_month,
        a.days_exposition,
        a.last_price,
        f.total_area,
        a.last_price / f.total_area AS square_meter_price
    FROM real_estate.advertisement AS a
    JOIN real_estate.flats AS f ON a.id = f.id
    JOIN real_estate.type AS t ON f.type_id = t.type_id
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND t.type = 'город'
      AND a.first_day_exposition >= DATE '2015-01-01'
      AND a.first_day_exposition < DATE '2019-01-01'
      AND a.last_price IS NOT NULL
      AND f.total_area > 0
),
publication_stats AS (
    SELECT
        publication_month AS month_number,
        COUNT(*) AS published_ads_count,
-- Добавил доли публикаций по месяцам
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS published_ads_share,
        ROUND(AVG(square_meter_price)::numeric, 2) AS avg_publication_square_meter_price,
        ROUND(AVG(total_area)::numeric, 2) AS avg_publication_total_area
    FROM prepared_ads
    GROUP BY publication_month
),
removal_stats AS (
    SELECT
        removal_month AS month_number,
        COUNT(*) AS removed_ads_count,
-- Добавил доли снятий по месяцам
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS removed_ads_share,
        ROUND(AVG(square_meter_price)::numeric, 2) AS avg_removed_square_meter_price,
        ROUND(AVG(total_area)::numeric, 2) AS avg_removed_total_area
    FROM prepared_ads
    WHERE days_exposition IS NOT NULL
    GROUP BY removal_month
),
-- Создаём справочник месяцев, чтобы в итоговой таблице были все 12 месяцев,
-- даже если по какому-то месяцу нет публикаций или снятий объявлений.
-- Также справочник позволяет вывести не только номер месяца, но и его название.
month_dict AS (
    SELECT *
    FROM (
        VALUES
            (1, 'January'),
            (2, 'February'),
            (3, 'March'),
            (4, 'April'),
            (5, 'May'),
            (6, 'June'),
            (7, 'July'),
            (8, 'August'),
            (9, 'September'),
            (10, 'October'),
            (11, 'November'),
            (12, 'December')
    ) AS months(month_number, month_name)
)
-- Используем COALESCE, чтобы заменить NULL на 0 в количестве объявлений.
-- NULL может появиться после LEFT JOIN, если в каком-то месяце не было публикаций или снятий.
-- Для количества событий лучше показывать 0, а не пустое значение.
SELECT
    m.month_number,
    m.month_name,
    COALESCE(p.published_ads_count, 0) AS published_ads_count,
    COALESCE(r.removed_ads_count, 0) AS removed_ads_count,
    p.published_ads_share,
    r.removed_ads_share,
    p.avg_publication_square_meter_price,
    r.avg_removed_square_meter_price,
    p.avg_publication_total_area,
    r.avg_removed_total_area
FROM month_dict AS m
LEFT JOIN publication_stats AS p ON m.month_number = p.month_number
LEFT JOIN removal_stats AS r ON m.month_number = r.month_number
ORDER BY m.month_number;
