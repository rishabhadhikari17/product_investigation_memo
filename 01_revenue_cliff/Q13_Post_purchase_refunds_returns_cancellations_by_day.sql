WITH days AS (
  SELECT DATE '2026-05-08' + n::int AS d
  FROM generate_series(0, 10) AS t(n)
)
SELECT days.d,
       coalesce(r.refunds, 0)         AS refunds,
       coalesce(r.refund_amount, 0)   AS refund_amount,
       coalesce(q.return_requests, 0) AS return_requests
FROM days
LEFT JOIN (SELECT created_at::date AS d, count(*) AS refunds, round(sum(amount)::numeric, 0) AS refund_amount
           FROM ecom.refunds GROUP BY 1) r ON r.d = days.d
LEFT JOIN (SELECT requested_at::date AS d, count(*) AS return_requests
           FROM ecom.return_requests GROUP BY 1) q ON q.d = days.d
ORDER BY days.d;
