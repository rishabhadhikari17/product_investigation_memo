# High-Views, Low-Conversion Paradox: Investigation Memo

Prepared for Rishabh · Oct 8, 2026 · Queries: `high_views_low_conversion_queries.sql` (P1-P9)

## Summary

154 products take about 26% of all product views but only about 3% of paid units. They convert badly at the very first step: only 7-12% of their views turn into an add-to-cart, against 34% for the rest of the catalogue. Price, stock, traffic source, device, return reasons and reviews all look normal, so none of them explains the gap. Reviews are thin everywhere (about 2 per product) and rate these products about the same as the rest, 4.0-4.2 stars. By elimination the likeliest cause is the product page itself, which this data cannot show.

This leak is separate from the May 13 revenue cliff. These products' share of views was 26.1% on May 13, inside its normal 24.8-27.3% range. The cliff happened at payment, this leak happens at add-to-cart.

## How the paradox was defined

- **Window:** 2026-04-19 to 2026-06-14, the span covered by `session_events`.
- **View share:** a product's share of all `product_view` events.
- **Purchase share:** a product's share of units in paid orders (`payment_status = 'paid'`). Purchase events carry no product id, so purchases come from `order_items` joined to `orders`.
- **Ratio:** view share divided by purchase share. A product is flagged at a ratio of 3 or more with at least 30 views.
- **Tiers:** "3-5x" (ratio 3 to under 5) and "5x+".

## What the data shows

| Tier | Products | Share of views | Share of paid units | View to add-to-cart | Units per view |
| --- | --- | --- | --- | --- | --- |
| 3-5x | 75 | 5.3% | 1.4% | 11.7% | 0.076 |
| 5x+ | 79 | 20.8% | 1.7% | 7.4% | 0.022 |
| All other products | 3,842 | 73.9% | 96.9% | 33.9% | 0.367 |

SQL: P1.

- **Most of the problem is above the 3-5x band.** Only 75 products sit in the 3-5x band you asked about. 79 sit above 5x and carry four times the views, so both tiers are reported.
- **A few products dominate.** The two worst are Suta Threads Velvet Kajal (ratio 71) and Indigo Lane Origins Longwear Eyeshadow Palette (ratio 74), both in Makeup. Together they drew 6,978 views and sold 27 units. SQL: P2.
- **SKU-level view.** The same two products show up at SKU level. SKU-02883-0008704 had 4,289 views and 3 units, and SKU-00801-0002389 had 2,553 views and 2 units. Other products in the list spread their views over several SKUs. SQL: P3.
- **The leak is early in the funnel.** Add-to-cart rates of 7-12% against 34% mean most visitors leave the product page without adding anything.
- **It is not a niche.** Every one of the 14 categories contains some of these products. Makeup has the highest share at 7.7% of its products (21 of 273). SQL: P7.

## What the data rules out

| Check | Paradox products | Rest of catalogue | Verdict |
| --- | --- | --- | --- |
| Price against category median | 1.07 (5x+), 1.16 (3-5x) | 1.14 | Not overpriced |
| Share of prices on sale | 33-40% | 34% | No difference |
| Sale price over list price | 0.95 | 0.955 | No difference |
| Average units on hand | 284-301 | 320 | Not out of stock |
| Return rate | 5.2-5.3% | 4.5% | Slightly higher, small gap |
| "Not as described" returns per unit | 0.5% | 0.6% | No difference |
| Defective or damaged returns per unit | 1.0-1.1% | 1.2% | No difference |
| Channel mix (organic, paid, referral, email, affiliate) | Within about 1 point | Same | Not a traffic-source issue |
| Mobile share of views | 72% | 72% | Not a device issue |
| Anonymous share of views | 35-37% | 26% | Somewhat more browsing-only traffic |

SQL: P4, P5, P5b, P6. Prices use the INDIA (INR) price list only. Reviews are covered in the next section.

## Reviews

The reviews table (8,000 reviews on 3,138 products, 4.12 stars on average) does not separate these products from the rest.

| Tier | Products with reviews | Reviews per product | Average rating | 1-2 star share | 5 star share |
| --- | --- | --- | --- | --- | --- |
| 3-5x | 57 of 75 | 1.8 | 4.17 | 10.5% | 51.1% |
| 5x+ | 60 of 79 | 1.9 | 3.97 | 14.4% | 47.1% |
| All other products | 3,018 of 3,842 | 2.0 | 4.13 | 10.5% | 49.5% |

SQL: P6b.

- **Ratings are similar.** The 3-5x tier rates slightly above the rest. The 5x+ tier rates 0.15 stars lower, but with only about 120 reviews behind it that gap is small and could be noise.
- **Reviews barely move conversion.** View-to-cart is 27% for products with no reviews, 25% with one, 28.5% with two and 28% with three or more. Products rated under 3 stars convert a little worse (23%) and are slightly more likely to be paradox products (5.0% against 3.2-4.0%), but that band holds only 202 products (SQL P6c).
- **Review volume is too thin to matter.** Most products have 0-2 reviews, so there is little signal for shoppers on any page. That is a catalogue-wide gap, not a feature of the paradox products.
- **The worst two have almost no reviews.** Velvet Kajal has 1 review (4.0 stars) and the Longwear Eyeshadow Palette has 5 (4.0 stars), against 4,334 and 2,644 views. One of the top 15, Drift & Dwell Classic Windcheater, has a single 1-star review (SQL P6d).

## How this relates to the May 13 revenue cliff

The two problems are separate and sit at opposite ends of the funnel.

| | Paradox leak | May 13 cliff |
| --- | --- | --- |
| Funnel stage | View to add-to-cart | Checkout to payment |
| Duration | Every day in the window | 09:00-17:00 on one day |
| Cause | Not found in this data | UPI gateway timeouts |

- **It did not cause the cliff.** If it had, these products' share of views would have moved on May 13. It was 26.1% (676 of 2,587 views), against 24.8-27.3% on May 8-18.
- **They were not hit harder by the outage.** These products were 2.7% of failed order value on May 13, in line with their share of paid revenue on other days (SQL P8). With only 9 of their order lines paid that day, the daily share is noisy, so no stronger claim is made.
- **Reading the funnel together matters.** Overall conversion on May 13 fell because payments failed. A team that read a conversion dip as a product-page problem would chase the wrong fix, and the reverse is also true.
- **The standing drag is real but small next to the cliff.** These products earned about 58,600 in paid revenue per day (3.2% of paid revenue) while taking 26% of views. The May 13 shortfall against the May 6-12 average was about 1.5M paid revenue in one day. SQL: P9.

## Open questions and caveats

- **Why do these pages fail to convert?** Page content, imagery, descriptions and variant selection are not in the data. Compare these pages with high-converting ones in the same category.
- **Are the views inflated?** Anonymous visitors are a larger share of their views (35-37% against 26%). Some of the views may be browsing, comparison shopping or automated traffic. Session-level depth and time on page would settle this.
- **Views cover only part of purchases.** Product-view events exist only for 2026-04-19 onward, and many purchases have no matching view event, so conversion figures are useful for comparing products, not as absolute rates.
- **Small samples.** Individual SKUs have few units (often under 10), so SKU ratios swing widely. The 30-view minimum reduces this but does not remove it.
- **Review data quality.** 32 of the 8,000 reviews are attached to orders whose payment failed (SQL P6e). Review dates run from 2026-03-17 to 2026-07-14, past the end of the event data, so reviews are matched to products, not to the analysis window.
- **Timestamps** are used as stored, with no time-zone conversion.

## Recommendations

1. **Audit the top 20 products first.** The highest-view products in P2 carry the most traffic into the leak. Start with the two Makeup products at ratio 71-74.
2. **Build up reviews on high-traffic products.** With about 2 reviews per product, most pages have little social proof. Ask recent buyers of the top paradox products for reviews first.
3. **Test the product page on the worst products.** Try clearer imagery, a review block, size or shade guidance and a visible add-to-cart button, and measure the view-to-cart rate.
4. **Track view-to-cart by product weekly.** Alert when a product holds 3x more view share than purchase share for two weeks.
5. **Keep this leak separate from payment health on dashboards.** Report view-to-cart and checkout-to-paid as two metrics so each problem is read for what it is.

## Query index
All queries are in 02_high_views_low_conversion_queries
- P1: paradox size by tier
- P2: top 25 paradox products
- P3: SKU-level view
- P4: pricing and stock
- P5, P5b: channel, device and anonymous share
- P6: return rates and reasons
- P6b-P6e: reviews by tier, reviews and conversion, reviews on top paradox products, review data quality
- P7: category spread
- P8: link to May 13, daily
- P9: standing daily drag
