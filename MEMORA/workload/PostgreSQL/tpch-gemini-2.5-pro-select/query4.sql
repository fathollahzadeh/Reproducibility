
SELECT o_orderpriority,
       count(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1993-07-01'
  AND o_orderdate < CAST('1993-07-01' AS DATE) + INTERVAL '3' MONTH
  AND o_orderkey IN
    (SELECT l_orderkey
     FROM lineitem
     WHERE l_commitdate < l_receiptdate)
GROUP BY o_orderpriority
ORDER BY o_orderpriority;