-- LTV ресторанов: суммарная комиссия сервиса за май — июнь 2021, топ-3.
-- rest_id остаётся в GROUP BY, чтобы точки одной сети не склеивались в одну строку.
WITH orders AS
  (SELECT events.rest_id,
          events.city_id,
          revenue * commission AS commission_revenue
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE revenue IS NOT NULL
     AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск')
SELECT partners.chain AS "Название сети",
       partners.type AS "Тип заведения",
       ROUND(SUM(commission_revenue)::numeric, 2) AS "LTV, ₽"
FROM orders
JOIN rest_analytics.partners ON orders.rest_id = partners.rest_id
                            AND orders.city_id = partners.city_id
GROUP BY orders.rest_id, partners.chain, partners.type
ORDER BY "LTV, ₽" DESC
LIMIT 3;
