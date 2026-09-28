-- Доля двух лидеров в общем LTV всех ресторанов Саранска
WITH orders AS
  (SELECT events.rest_id,
          revenue * commission AS commission_revenue
   FROM rest_analytics.analytics_events AS events
   JOIN rest_analytics.cities cities ON events.city_id = cities.city_id
   WHERE revenue IS NOT NULL
     AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
     AND city_name = 'Саранск'),
rest_ltv AS
  (SELECT rest_id,
          SUM(commission_revenue) AS ltv,
          ROW_NUMBER() OVER (ORDER BY SUM(commission_revenue) DESC) AS rn
   FROM orders
   GROUP BY rest_id)
SELECT COUNT(*) AS "Ресторанов",
       ROUND(SUM(ltv)::numeric, 2) AS "Общий LTV, ₽",
       ROUND((SUM(ltv) FILTER (WHERE rn <= 2) / SUM(ltv) * 100)::numeric, 1) AS "Доля топ-2, %"
FROM rest_ltv;
