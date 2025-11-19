--customer life time value
 WITH recent_sales AS
  (SELECT s.CUSTOMER_ID,
          s.SALE_ID,
          s.SALE_DATE,
          s.SALE_AMOUNT,
          s.SKU_ID,
          ROW_NUMBER() OVER (PARTITION BY s.CUSTOMER_ID
                             ORDER BY s.SALE_DATE DESC) AS rn
   FROM {{DB_CORE_SALES}}.{{SCHM_CURATED_SALES}}.{{TBL_SALES}} s
   WHERE s.SALE_DATE >= DATEADD(year, -1, CURRENT_DATE)),
      latest_sale AS
  (SELECT CUSTOMER_ID,
          SALE_DATE AS LAST_PURCHASE_DATE,
          SALE_AMOUNT AS LAST_PURCHASE_AMOUNT
   FROM recent_sales
   WHERE rn = 1),
      customer_discounts AS
  (SELECT s.CUSTOMER_ID,
          COUNT(DISTINCT d.DISCOUNT_ID) AS discount_count,
          AVG(d.DISCOUNT_PERCENT) AS avg_discount
   FROM {{DB_CORE_SALES}}.{{SCHM_CURATED_SALES}}.{{TBL_SALES}} s
   LEFT JOIN {{DB_CORE_PR}}.{{SCHM_CURATED_DISCOUNT}}.{{TBL_DISCOUNTS}} d ON s.SKU_ID = d.SKU_ID
   AND s.SALE_DATE = d.DISCOUNT_DATE
   WHERE d.DISCOUNT_PERCENT IS NOT NULL
   GROUP BY s.CUSTOMER_ID),
      lifetime_value AS
  (SELECT c.CUSTOMER_ID,
          SUM(s.SALE_AMOUNT) AS total_sales,
          COUNT(s.SALE_ID) AS total_transactions,
          MIN(s.SALE_DATE) AS first_purchase,
          MAX(s.SALE_DATE) AS last_purchase
   FROM {{DB_CORE}}.{{SCHM_CURATED_CUSTOMER}}.{{TBL_CUSTOMERS}} c
   LEFT JOIN {{DB_CORE_SALES}}.{{SCHM_CURATED_SALES}}.{{TBL_SALES}} s ON c.CUSTOMER_ID = s.CUSTOMER_ID
   GROUP BY c.CUSTOMER_ID)
SELECT lv.CUSTOMER_ID,
       lv.total_sales,
       lv.total_transactions,
       lv.first_purchase,
       lv.last_purchase,
       ls.LAST_PURCHASE_DATE,
       ls.LAST_PURCHASE_AMOUNT,
       cd.discount_count,
       cd.avg_discount,
       CASE
           WHEN lv.total_sales > 10000 THEN 'High Value'
           WHEN lv.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_segment
FROM lifetime_value lv
LEFT JOIN latest_sale ls ON lv.CUSTOMER_ID = ls.CUSTOMER_ID
LEFT JOIN customer_discounts cd ON lv.CUSTOMER_ID = cd.CUSTOMER_ID
WHERE lv.total_transactions > 1
ORDER BY lv.total_sales DESC;