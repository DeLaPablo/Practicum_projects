/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Арсений Павлович
 * Дата: 28.04.2026
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT 
		COUNT(id) AS total_players,
		COUNT(id) FILTER (WHERE payer = 1) AS paying_users,
		COUNT(id) FILTER (WHERE payer = 1) / COUNT(id)::numeric AS paying_users_share
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT 
		r.race,
		COUNT(u.id) FILTER (WHERE u.payer = 1) AS paying_users,
		COUNT(u.id) AS total_players,
		COUNT(u.id) FILTER (WHERE u.payer = 1) / COUNT(u.id)::numeric AS paying_users_share
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY r.race;


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT 
		COUNT(transaction_id) AS total_purchases,
		SUM(amount) AS total_purchase_amount,
		MIN(amount) AS min_purchase_amount,
		MAX(amount) AS max_purchase_amount,
		AVG(amount) AS avg_purchase_amount,
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median_purchase_amount,
		STDDEV(amount) AS stddev_purchase_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
SELECT 
		COUNT(transaction_id) FILTER (WHERE amount = 0) AS zero_amount_purchases,
		COUNT(transaction_id) FILTER (WHERE amount = 0) / COUNT(transaction_id)::numeric AS zero_amount_purchases_share
FROM fantasy.events;

-- 2.3: Популярные эпические предметы:
WITH item_sales_stats AS (
	SELECT 
			i.game_items,
			COUNT(e.transaction_id) FILTER (WHERE e.amount != 0) AS total_sales,
			COUNT(DISTINCT e.id) FILTER (WHERE e.amount != 0) AS buyers_count
	FROM fantasy.items AS i
	JOIN fantasy.events AS e ON i.item_code = e.item_code
	GROUP BY i.game_items
)
SELECT 
		game_items,
    	total_sales,
    	total_sales / SUM(total_sales) OVER()::numeric AS sales_share,
    	buyers_count,
    	buyers_count / (
        	SELECT COUNT(DISTINCT id)
       		FROM fantasy.events
        	WHERE amount != 0
    			)::numeric AS buyers_share
FROM item_sales_stats
ORDER BY buyers_share DESC;

-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
SELECT
		r.race,
		COUNT(DISTINCT u.id) AS total_players,
		COUNT(DISTINCT u.id) FILTER (WHERE e.amount != 0) AS buyers_count,
		COUNT(DISTINCT u.id) FILTER (WHERE e.amount != 0) / COUNT(DISTINCT u.id)::numeric AS buyers_share,
		COUNT(DISTINCT u.id) FILTER (WHERE u.payer = 1 AND e.amount != 0) / COUNT(DISTINCT u.id) FILTER (WHERE e.amount != 0)::numeric AS payer_buyers_share,
		COUNT(e.transaction_id) FILTER (WHERE e.amount != 0) / COUNT(DISTINCT u.id) FILTER (WHERE e.amount != 0)::numeric AS avg_purchases_per_buyer,
		AVG(e.amount) FILTER (WHERE e.amount != 0) AS avg_purchase_amount,
		SUM(e.amount) FILTER (WHERE e.amount != 0) / COUNT(DISTINCT u.id) FILTER (WHERE e.amount != 0)::numeric AS avg_total_amount_per_buyer
FROM fantasy.users AS u
LEFT JOIN fantasy.events AS e ON u.id = e.id
JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY r.race
ORDER BY buyers_share DESC;