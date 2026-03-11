
SELECT l_shipmode,
       count(*) FILTER (
                        WHERE o_orderpriority IN ('1-URGENT', '2-HIGH')) AS high_line_count,
       count(*) FILTER (
                        WHERE o_orderpriority NOT IN ('1-URGENT', '2-HIGH')) AS low_line_count
FROM orders,
     lineitem
WHERE o_orderkey = l_orderkey
  AND l_shipmode IN ('MAIL', 'SHIP')
  AND l_commitdate < l_receiptdate
  AND l_shipdate < l_commitdate
  AND l_receiptdate >= DATE '1994-01-01'
  AND l_receiptdate < CAST('1994-01-01' AS DATE) + INTERVAL '1' YEAR
GROUP BY l_shipmode
ORDER BY l_shipmode;