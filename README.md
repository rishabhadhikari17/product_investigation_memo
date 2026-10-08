# Ecommerce Investigations (`ecom`)

Three investigations on one ecommerce dataset (PostgreSQL schema `ecom`, orders from 2026-03-16 to 2026-06-14). Each folder has an `INVESTIGATION.md` memo and the SQL queries behind it.

| # | Investigation | Core question | Answer in one line |
| --- | --- | --- | --- |
| 1 | 01_revenue_cliff/revenue_cliff_investigation.md | Why did paid orders fall 55% on one day? | A UPI payment outage from 09:00 to 16:55 |
| 2 | 02_high_views_low_conversion | Why do some products get 3-5x more view share than purchase share? | A product-page leak at add-to-cart that price, stock, traffic and reviews do not explain |
| 3 | 03_coupon_cannibalization | Do coupons bring new demand or subsidise purchases that would happen anyway? | No evidence of lift, and they cost about 2.7% of paid order value |

## Repository layout

```
01_revenue_cliff/                 INVESTIGATION.md, revenue_cliff_queries.sql (Q1-Q18)
02_high_views_low_conversion/     INVESTIGATION.md, high_views_low_conversion_queries.sql (P1-P9)
03_coupon_cannibalization/        INVESTIGATION.md, coupon_cannibalization_queries.sql (C1-C11)
```

## 1. The May 13 revenue cliff

**Problem.** Daily revenue fell sharply on May 13, 2026 (described as about 60%, measured as a 55% fall in paid orders). Was it gateway failures, stockouts, marketing drops or funnel drop-offs?

**Hypotheses.** Gateway failure, funnel drop-off, traffic or marketing drop, stockout, pricing and promotions, refunds and returns, late-posting payments.

**Conclusions**

- A UPI outage from 09:00 to 16:55 caused it. All 171 UPI payments in that window failed, on every gateway, and 168 of them were gateway timeouts. The other six hypotheses were ruled out.
- Paid orders fell 55% and paid revenue 63% against the May 6-12 average. The dashboard showed only -23% because it counted failed orders as revenue.
- 157 orders failed (about 1.01M). 66 of the 130 affected customers had not paid again within 7 days.

## 2. High-views, low-conversion paradox

**Problem.** Find products whose view share is 3-5x their purchase share, and diagnose them using SKU-level conversion, pricing and reviews.

**Hypotheses.** Overpriced, out of stock, low-quality traffic, poor quality (returns), bad or missing reviews, and a product-page problem.

**Conclusions**

- 154 products take about 26% of views but about 3% of paid units. 75 sit in the 3-5x band and 79 above 5x.
- They leak at add-to-cart (7-12% of views against 34% for other products). Price, stock, traffic mix, returns and reviews (about 4.1 stars, 0-2 reviews per product) all look normal.
- By elimination the likeliest cause is the product page, which this data cannot show.

## 3. Coupon cannibalization

**Problem.** Marketing says coupons drive net-new acquisition and volume. Finance says they subsidise organic purchases and erode margin. Which is right?

**Hypotheses.** Coupons lift basket size, volume and retention, pull purchases forward, are limited to first-time buyers, and are targeted at the right customers.

**Conclusions**

- The data supports Finance. Coupon and non-coupon orders have the same basket (6,334 vs 6,335), the same retention and the same purchase pace. About 22% of orders use a coupon in every week and every segment.
- 78% of WELCOME10, WELCOME15 and FIRSTBUY redemptions are by repeat buyers.
- Percent and BOGO coupons cost about 17% of the order for a basket lift of 1% or less. Modeled discounts total about 6.4M (2.7% of paid value), and 79% of that goes to existing customers.
- Without a holdout group, true incrementality cannot be proven. A holdout test is the main recommendation.

## How the three connect

| | Revenue cliff | Paradox | Coupons |
| --- | --- | --- | --- |
| Where in the funnel | Checkout to payment | View to add-to-cart | Price at purchase |
| Time pattern | One day, 8 hours | Every day | Every day |
| Cause found | Yes: UPI timeouts | No: product page suspected | Partly: untargeted discounts |
| Type of loss | Lost sales | Lost sales | Given-away margin |

- **Separate problems.** The paradox products held 26.1% of views on May 13, inside their normal range, so they did not cause the cliff. Coupon share on May 13 was 22.7%, in line with other days.
- **One theme.** In all three, the headline number hides the real mechanism. Revenue counted failed orders, views counted browsers rather than buyers, and coupon orders counted discounted sales as growth.
- **Shared fixes.** Record the discount on each order, define revenue as paid orders only, add product cost so margin can be measured, and track each funnel step as its own metric.

## Conventions and caveats

- **Paid** means `orders.payment_status = 'paid'`. Timestamps are used as stored, with no time-zone conversion.
- Queries are written in PostgreSQL syntax and validated in DuckDB against the CSV exports.
- Known data caveats: about 8% of orders use the USD price list, `orders.discount` is 0 on every row, coupon names do not match their discount types, and 32 reviews are attached to failed orders.
- Investigations 2 and 3 have no experiment behind them, so their conclusions come from comparing behaviour rather than from measured lift.
