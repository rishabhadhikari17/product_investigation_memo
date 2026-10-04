SELECT pt.txn_time::date AS d,
       count(*)                                                        AS upi_txns,
       count(*) FILTER (WHERE pt.status = 'failed')                    AS failed,
       round(100.0 * count(*) FILTER (WHERE pt.status = 'failed') / count(*), 1) AS fail_pct
FROM ecom.payment_transactions pt
JOIN ecom.payment_intents i  ON i.payment_intent_id = pt.payment_intent_id
JOIN ecom.payment_methods pm ON pm.payment_method_id = i.payment_method_id
WHERE pm.method_name = 'upi'
  AND pt.txn_time >= '2026-05-08' AND pt.txn_time < '2026-05-19'
GROUP BY 1
ORDER BY 1;
