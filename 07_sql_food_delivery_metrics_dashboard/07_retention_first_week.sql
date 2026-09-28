-- Retention Rate первой недели для новых клиентов, %. День 0 участвует в знаменателе, но не выводится.
-- Новые пользователи: первое посещение с 1 мая по 24 июня (чтобы у всех прошла неделя)
WITH new_users AS
  (SELECT DISTINCT first_date,
                   user_id
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
     AND city_name = 'Саранск'),
-- Активные пользователи по дате любого события
active_users AS
  (SELECT DISTINCT log_date,
                   user_id
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск'),
-- Сколько дней прошло с первого визита до каждого возвращения
daily_retention AS
  (SELECT n.user_id,
          first_date,
          log_date::date - first_date::date AS day_since_install
   FROM new_users AS n
   JOIN active_users AS a ON n.user_id = a.user_id
   AND log_date >= first_date)
SELECT *
FROM (SELECT day_since_install AS "День с момента первого визита",
             COUNT(DISTINCT user_id) AS "Вернулось клиентов",
             ROUND((100.0 * COUNT(DISTINCT user_id) / MAX(COUNT(DISTINCT user_id)) OVER (ORDER BY day_since_install))::numeric, 1) AS "Retention Rate, %"
      FROM daily_retention
      WHERE day_since_install < 8
      GROUP BY day_since_install) AS rr
WHERE "День с момента первого визита" > 0
ORDER BY "День с момента первого визита";
