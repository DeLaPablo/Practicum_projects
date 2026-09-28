-- Топ-5 блюд по LTV в двух ресторанах-лидерах; состав — по признакам разметки meat / fish
WITH orders AS
  (SELECT events.rest_id,
          events.city_id,
          events.object_id,
          revenue * commission AS commission_revenue
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE revenue IS NOT NULL
     AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск'),
top_ltv_restaurants AS
  (SELECT orders.rest_id, chain
   FROM orders
   JOIN rest_analytics.partners p ON orders.rest_id = p.rest_id AND orders.city_id = p.city_id
   GROUP BY orders.rest_id, chain
   ORDER BY SUM(commission_revenue) DESC
   LIMIT 2)
SELECT d.name AS "Блюдо",
       t.chain AS "Ресторан",
       CASE WHEN d.meat = 1 AND d.fish = 1 THEN 'Мясное + рыбное (по разметке)'
            WHEN d.meat = 1 THEN 'Мясное'
            WHEN d.fish = 1 THEN 'Рыбное'
            ELSE 'Без мяса и рыбы' END AS "Состав",
       ROUND(SUM(o.commission_revenue)::numeric, 2) AS "LTV, ₽"
FROM orders o
JOIN top_ltv_restaurants t ON t.rest_id = o.rest_id
JOIN rest_analytics.dishes d ON d.object_id = o.object_id AND d.rest_id = o.rest_id
GROUP BY 1, 2, 3
ORDER BY "LTV, ₽" DESC
LIMIT 5;
