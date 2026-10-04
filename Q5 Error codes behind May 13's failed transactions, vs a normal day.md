SELECT coalesce(error_code, '(none)')            AS error_code,
       min(error_message)                        AS example_message,
       count(*) FILTER (WHERE txn_time >= '2026-05-13' AND txn_time < '2026-05-14')           AS may13,
       round(count(*) FILTER (WHERE txn_time >= '2026-05-06' AND txn_time < '2026-05-13') / 7.0, 1) AS avg_per_day_prev_7d
FROM ecom.payment_transactions
WHERE status = 'failed'
  AND txn_time >= '2026-05-06' AND txn_time < '2026-05-14'
GROUP BY 1
ORDER BY may13 DESC;
