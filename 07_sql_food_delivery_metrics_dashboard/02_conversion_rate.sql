-- Conversion Rate: доля клиентов, оформивших заказ, среди всех активных за день (Саранск, май — июнь 2021)
SELECT log_date AS "Дата",
       ROUND((COUNT(DISTINCT user_id) FILTER (WHERE event = 'order')) / COUNT(DISTINCT user_id)::numeric, 2) AS "Конверсия в заказ"
FROM rest_analytics.analytics_events AS events
JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
  AND city_name = 'Саранск'
GROUP BY log_date
ORDER BY log_date;
