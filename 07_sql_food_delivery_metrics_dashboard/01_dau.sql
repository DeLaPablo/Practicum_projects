-- DAU: количество уникальных клиентов, оформивших заказ, по дням (Саранск, май — июнь 2021)
SELECT log_date AS "Дата",
       COUNT(DISTINCT user_id) AS "Активные клиенты"
FROM rest_analytics.analytics_events AS events
JOIN rest_analytics.cities AS cities ON events.city_id = cities.city_id
WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
  AND city_name = 'Саранск'
  AND event = 'order'
GROUP BY log_date
ORDER BY log_date;
