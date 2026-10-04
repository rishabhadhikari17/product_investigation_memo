-- Coupon and promo usage by day (share of orders)
SELECT created_at::date AS d,
       count(*)                                                       AS orders,
       count(*) FILTER (WHERE applied_coupon_id IS NOT NULL)          AS coupon_orders,
       count(*) FILTER (WHERE applied_promo_id  IS NOT NULL)          AS promo_orders,
       round(100.0 * count(*) FILTER (WHERE applied_coupon_id IS NOT NULL) / count(*), 1) AS coupon_pct,
       round(100.0 * count(*) FILTER (WHERE applied_promo_id  IS NOT NULL) / count(*), 1) AS promo_pct,
       sum(discount)                                                  AS discount_recorded
FROM ecom.orders
WHERE created_at >= '2026-05-08' AND created_at < '2026-05-19'
GROUP BY 1
ORDER BY 1;


-- Price rows by validity start date (all loaded once, none end-dated)
SELECT valid_from::date AS valid_from_day, count(*) AS price_rows,
       count(*) FILTER (WHERE valid_to IS NOT NULL) AS with_end_date
FROM ecom.prices
GROUP BY 1
ORDER BY 1;


-- Promotions and coupons live on May 13 (all of them, for the whole period)
SELECT 'promotions' AS kind, count(*) AS live_on_may13,
       min(starts_at) AS earliest_start, max(ends_at) AS latest_end
FROM ecom.promotions
WHERE starts_at <= '2026-05-13' AND ends_at >= '2026-05-13'
UNION ALL
SELECT 'coupons', count(*), min(starts_at), max(ends_at)
FROM ecom.coupons
WHERE starts_at <= '2026-05-13' AND ends_at >= '2026-05-13';
