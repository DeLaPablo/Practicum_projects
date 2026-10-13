-- Продуктовые метрики Яндекс Книг (PostgreSQL, схема bookmate), 01.09–11.12.2024

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
