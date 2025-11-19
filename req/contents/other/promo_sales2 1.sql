
WITH promo_sales AS (
    select        p.PROMO_ID,        p.PROMO_NAME,       s.SALE_ID,        s.SALE_AMOUNT,        s.SALE_DATE
    from
        CORE_PR.CURATED_PROMO.PROMOTIONS p
    left JOIN
        CORE_SALES.CURATED_SALES.SALES s
        ON p.PROMO_ID = s.PROMO_ID
    WHERE
        p.START_DATE >= '2024-01-01'
        AND p.END_DATE <= '2024-06-30'
),
promo_agg AS (
    SELECT
        PROMO_ID,
        PROMO_NAME,
        COUNT(SALE_ID) AS total_sales,
        SUM(SALE_AMOUNT) AS total_amount,
        AVG(SALE_AMOUNT) AS avg_sale,
        MIN(SALE_DATE) AS first_sale,
        MAX(SALE_DATE) AS last_sale
    FROM
        promo_sales
    GROUP BY
        PROMO_ID, PROMO_NAME
),
promo_discount AS (
    SELECT
        p.PROMO_ID,
        MAX(d.DISCOUNT_PERCENT) AS max_discount,
        AVG(d.DISCOUNT_PERCENT) AS avg_discount
    FROM
        CORE_PR.CURATED_PROMO.PROMOTIONS p
    LEFT JOIN
        CORE_PR.CURATED_DISCOUNT.DISCOUNTS d
        ON p.PROMO_ID = d.PROMO_ID
    GROUP BY
        p.PROMO_ID
)
SELECT
    pa.PROMO_ID,
    pa.PROMO_NAME,
    pa.total_sales,
    pa.total_amount,
    pa.avg_sale,
    pa.first_sale,
    pa.last_sale,
    pd.max_discount,
    pd.avg_discount,
    CASE
        WHEN pa.total_amount > 10000 THEN 'Successful'
        WHEN pa.total_amount BETWEEN 5000 AND 10000 THEN 'Moderate'
        ELSE 'Needs Review'
    END AS promo_status
FROM
    promo_agg pa
LEFT JOIN
    promo_discount pd ON pa.PROMO_ID = pd.PROMO_ID
ORDER BY
    pa.total_amount DESC;
