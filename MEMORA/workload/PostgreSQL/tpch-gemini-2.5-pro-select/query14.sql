WITH relevant_lineitems AS
  (SELECT l_partkey,
          l_extendedprice * (1 - l_discount) AS revenue
   FROM lineitem
   WHERE l_shipdate >= DATE '1995-09-01'
     AND l_shipdate < CAST('1995-09-01' AS DATE) + INTERVAL '1' MONTH)
SELECT 100.00 * sum(CASE
                        WHEN pp.p_partkey IS NOT NULL THEN r.revenue
                        ELSE 0
                    END) / sum(r.revenue)
FROM relevant_lineitems r
LEFT JOIN
  (SELECT p_partkey
   FROM part
   WHERE p_type LIKE 'PROMO%') pp ON r.l_partkey = pp.p_partkey;