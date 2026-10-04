SELECT pl.name AS price_list, pl.currency,
       count(*)                       AS orders,
       round(avg(o.total)::numeric, 0) AS avg_total
FROM ecom.orders o
JOIN ecom.price_lists pl ON pl.price_list_id = o.price_list_id
GROUP BY 1, 2
ORDER BY 3 DESC;
