SELECT
    region.REGION,
    region.total_sales,
    region.avg_discount,
    region.top_sku,
    region.top_sku_sales,
    region.customer_count,
    CASE
        WHEN region.total_sales > 100000 THEN 'High Sales Region'
        ELSE 'Other Region'
    END AS region_category
FROM (
    SELECT
        s.REGION,
        SUM(s.SALE_AMOUNT) AS total_sales,
        AVG(d.DISCOUNT_PERCENT) AS avg_discount,
        (
            SELECT TOP 1 sku.SKU_ID
            FROM CORE.CURATED_SKU.SKUS sku
            JOIN CORE_SALES.CURATED_SALES.SALES ss
                ON sku.SKU_ID = ss.SKU_ID
            WHERE ss.REGION = s.REGION
            GROUP BY sku.SKU_ID
            ORDER BY SUM(ss.SALE_AMOUNT) DESC
        ) AS top_sku,
        (
            SELECT SUM(ss.SALE_AMOUNT)
            FROM CORE_SALES.CURATED_SALES.SALES ss
            WHERE ss.REGION = s.REGION
                AND ss.SKU_ID = (
                    SELECT TOP 1 sku2.SKU_ID
                    FROM CORE.CURATED_SKU.SKUS sku2
                    JOIN CORE_SALES.CURATED_SALES.SALES sss
                        ON sku2.SKU_ID = sss.SKU_ID
                    WHERE sss.REGION = s.REGION
                    GROUP BY sku2.SKU_ID
                    ORDER BY SUM(sss.SALE_AMOUNT) DESC
                )
        ) AS top_sku_sales,
        COUNT(DISTINCT s.CUSTOMER_ID) AS customer_count
    FROM
        CORE_SALES.CURATED_SALES.SALES s
    LEFT JOIN
        CORE_PR.CURATED_DISCOUNT.DISCOUNTS d
        ON s.SKU_ID = d.SKU_ID AND s.SALE_DATE = d.DISCOUNT_DATE
    GROUP BY
        s.REGION
) region
ORDER BY
    region.total_sales DESC;
