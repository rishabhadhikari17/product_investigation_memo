WITH pdp_base AS (
  WITH v AS (
    SELECT product_id::bigint AS pid, count(*) AS n_views
    FROM ecom.session_events WHERE event_type = 'product_view' GROUP BY 1
  ), c AS (
    SELECT product_id::bigint AS pid, count(*) AS n_carts
    FROM ecom.session_events WHERE event_type = 'add_to_cart' GROUP BY 1
  ), p AS (
    SELECT pv.product_id AS pid, sum(oi.qty) AS units, sum(oi.line_total) AS revenue
    FROM ecom.order_items oi
    JOIN ecom.orders o ON o.order_id = oi.order_id
    JOIN ecom.product_variants pv ON pv.variant_id = oi.variant_id
    WHERE lower(o.payment_status) = 'paid' AND o.created_at >= '2026-04-19'
    GROUP BY 1
  ), j AS (
    SELECT v.pid, v.n_views, coalesce(c.n_carts, 0) AS n_carts,
           coalesce(p.units, 0) AS units, coalesce(p.revenue, 0) AS revenue
    FROM v LEFT JOIN c ON c.pid = v.pid LEFT JOIN p ON p.pid = v.pid
  )
  SELECT j.*,
         j.n_views::float8 / sum(j.n_views) OVER ()                                    AS view_share,
         j.units::float8 / sum(j.units) OVER ()                                        AS purchase_share,
         (j.n_views::float8 / sum(j.n_views) OVER ())
           / nullif(j.units::float8 / sum(j.units) OVER (), 0)                         AS ratio,
         CASE WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 5 THEN '5x+'
              WHEN j.n_views >= 30
               AND (j.n_views::float8 / sum(j.n_views) OVER ())
                   / nullif(j.units::float8 / sum(j.units) OVER (), 0) >= 3 THEN '3-5x'
              ELSE 'rest' END                                                          AS tier
  FROM j
),
pr AS (
  SELECT v.product_id AS pid,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY coalesce(p.sale_price, p.list_price)) AS sale_price,
         percentile_cont(0.5) WITHIN GROUP (ORDER BY p.list_price)                         AS list_price,
         avg(CASE WHEN p.sale_price IS NOT NULL AND p.sale_price < p.list_price THEN 1 ELSE 0 END) AS share_on_sale
  FROM ecom.prices p JOIN ecom.product_variants v ON v.variant_id = p.variant_id
  WHERE p.price_list_id = 1
  GROUP BY 1
), cm AS (
  SELECT pd.category_id, percentile_cont(0.5) WITHIN GROUP (ORDER BY pr.sale_price) AS cat_median
  FROM pr JOIN ecom.products pd ON pd.product_id = pr.pid
  GROUP BY 1
), idx AS (
  SELECT pr.pid, pr.sale_price / cm.cat_median AS price_index_in_category,
         pr.share_on_sale, pr.sale_price / pr.list_price AS sale_over_list
  FROM pr
  JOIN ecom.products pd ON pd.product_id = pr.pid
  JOIN cm ON cm.category_id = pd.category_id
), st AS (
  SELECT v.product_id AS pid, sum(i.on_hand) AS on_hand
  FROM ecom.inventory_items i JOIN ecom.product_variants v ON v.variant_id = i.variant_id GROUP BY 1
)
SELECT b.tier, count(*) AS products,
       round(avg(idx.price_index_in_category)::numeric, 2) AS avg_price_index,
       round(avg(idx.share_on_sale)::numeric, 3)           AS share_of_prices_on_sale,
       round(avg(idx.sale_over_list)::numeric, 3)          AS sale_over_list,
       round(avg(st.on_hand)::numeric, 0)                  AS avg_on_hand
FROM pdp_base b
LEFT JOIN idx ON idx.pid = b.pid
LEFT JOIN st  ON st.pid = b.pid
GROUP BY b.tier ORDER BY b.tier;
