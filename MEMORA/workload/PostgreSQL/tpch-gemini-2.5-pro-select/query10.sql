
SELECT c.c_custkey,
       c.c_name,
       cr.revenue,
       c.c_acctbal,
       n.n_name,
       c.c_address,
       c.c_phone,
       c.c_comment
FROM
  (SELECT o.o_custkey,
          SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
   FROM orders o
   JOIN lineitem l ON l.l_orderkey = o.o_orderkey
   WHERE o.o_orderdate >= DATE '1993-10-01'
     AND o.o_orderdate < CAST('1993-10-01' AS DATE) + INTERVAL '3' MONTH
     AND l.l_returnflag = 'R'
   GROUP BY o.o_custkey) AS cr
JOIN customer c ON c.c_custkey = cr.o_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
ORDER BY cr.revenue DESC
LIMIT 20;