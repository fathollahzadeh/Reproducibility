WITH AggLineitem AS
  (SELECT l_partkey,
          l_suppkey,
          0.5 * sum(l_quantity) AS required_qty
   FROM lineitem
   WHERE l_shipdate >= DATE '1994-01-01'
     AND l_shipdate < CAST('1994-01-01' AS DATE) + INTERVAL '1' YEAR
   GROUP BY l_partkey,
            l_suppkey)
SELECT s.s_name,
       s.s_address
FROM nation n
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON p.p_partkey = ps.ps_partkey
JOIN AggLineitem l_agg ON l_agg.l_partkey = ps.ps_partkey
AND l_agg.l_suppkey = ps.ps_suppkey
WHERE n.n_name = 'CANADA'
  AND p.p_name LIKE 'forest%'
  AND ps.ps_availqty > l_agg.required_qty
GROUP BY s.s_suppkey,
         s.s_name,
         s.s_address
ORDER BY s.s_name;