-- 1. MAU авторов в ноябре 2024, топ-3
SELECT main_author_name,
       COUNT(DISTINCT puid) AS mau
FROM bookmate.audition AS ba
JOIN bookmate.content AS bc ON ba.main_content_id = bc.main_content_id
JOIN bookmate.author AS bau ON bc.main_author_id = bau.main_author_id
WHERE DATE_TRUNC('month', msk_business_dt_str::timestamp) = '2024-11-01'
GROUP BY main_author_name
ORDER BY mau DESC
LIMIT 3;

-- 2. MAU произведений в ноябре 2024, топ-3
SELECT main_content_name,
       published_topic_title_list,
       main_author_name,
       COUNT(DISTINCT puid) AS mau
FROM bookmate.audition AS ba
JOIN bookmate.content AS bc ON ba.main_content_id = bc.main_content_id
JOIN bookmate.author AS bau ON bc.main_author_id = bau.main_author_id
WHERE DATE_TRUNC('month', msk_business_dt_str::timestamp) = '2024-11-01'
GROUP BY main_author_name, main_content_name, published_topic_title_list
ORDER BY mau DESC
LIMIT 3;

-- 3. Ежедневный Retention пользователей, активных 2 декабря
WITH unique_december_ids AS (
    SELECT DISTINCT puid
    FROM bookmate.audition
    WHERE msk_business_dt_str::date = '2024-12-02'
),
day_active AS (
    SELECT DISTINCT u.puid,
           msk_business_dt_str::date AS log_date
    FROM unique_december_ids AS u
    JOIN bookmate.audition AS ba ON u.puid = ba.puid
    WHERE msk_business_dt_str::date >= '2024-12-02'
)
SELECT log_date - '2024-12-02'::date AS day_since_install,
       COUNT(DISTINCT puid) AS retained_users,
       ROUND(COUNT(DISTINCT puid)::numeric / MAX(COUNT(DISTINCT puid)) OVER (), 2) AS retention_rate
FROM day_active
GROUP BY day_since_install
ORDER BY day_since_install;

-- 4. Средний LTV в Москве и Санкт-Петербурге (399 ₽ за каждый активный месяц)
WITH active_users AS (
    SELECT DISTINCT ba.puid,
           usage_geo_id_name AS city,
           DATE_TRUNC('month', ba.msk_business_dt_str::timestamp) AS month
    FROM bookmate.audition AS ba
    JOIN bookmate.geo AS g ON ba.usage_geo_id = g.usage_geo_id
    WHERE g.usage_geo_id_name IN ('Москва', 'Санкт-Петербург')
)
SELECT city,
       COUNT(DISTINCT puid) AS total_users,
       ROUND(COUNT(*) * 399 / COUNT(DISTINCT puid)::numeric, 2) AS ltv
FROM active_users
GROUP BY city;

-- 5. Средняя выручка с часа чтения/прослушивания, сентябрь–ноябрь
SELECT DATE_TRUNC('month', msk_business_dt_str::date)::date AS month,
       COUNT(DISTINCT puid) AS mau,
       ROUND(SUM(hours)::numeric, 2) AS hours,
       ROUND(COUNT(DISTINCT puid)::numeric * 399 / SUM(hours)::numeric, 2) AS avg_hour_rev
FROM bookmate.audition
WHERE msk_business_dt_str::date < '2024-12-01'
GROUP BY month
ORDER BY month;

-- 6. Подготовка данных для проверки гипотезы: часы активности пользователей Москвы и СПб
SELECT bg.usage_geo_id_name AS city,
       ba.puid,
       SUM(ba.hours) AS hours
FROM bookmate.audition AS ba
JOIN bookmate.geo AS bg ON ba.usage_geo_id = bg.usage_geo_id
WHERE bg.usage_geo_id_name IN ('Москва', 'Санкт-Петербург')
GROUP BY city, ba.puid;
