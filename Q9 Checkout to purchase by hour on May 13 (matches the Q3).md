SELECT EXTRACT(HOUR FROM occurred_at)::int AS hr,
       count(DISTINCT session_id) FILTER (WHERE event_type = 'begin_checkout') AS begin_checkout,
       count(DISTINCT session_id) FILTER (WHERE event_type = 'purchase')       AS purchase,
       round(count(DISTINCT session_id) FILTER (WHERE event_type = 'purchase')::numeric
             / nullif(count(DISTINCT session_id) FILTER (WHERE event_type = 'begin_checkout'), 0), 2) AS checkout_to_purchase
FROM ecom.session_events
WHERE occurred_at >= '2026-05-13' AND occurred_at < '2026-05-14'
GROUP BY 1
ORDER BY 1;
