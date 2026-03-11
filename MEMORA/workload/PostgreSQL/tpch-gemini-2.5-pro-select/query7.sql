
SELECT n1.n_name AS supp_nation,
       n2.n_name AS cust_nation,
       extract(YEAR
               FROM l.l_shipdate) AS l_year,
       sum(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM nation n1
JOIN supplier s ON n1.n_nationkey = s.s_nationkey
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n2 ON c.c_nationkey = n2.n_nationkey
WHERE l.l_shipdate BETWEEN date '1995-01-01' AND date '1996-12-31'
  AND ((n1.n_name = 'FRANCE'
        AND n2.n_name = 'GERMANY')
       OR (n1.n_name = 'GERMANY'
           AND n2.n_name = 'FRANCE'))
GROUP BY n1.n_name,
         n2.n_name,
         l_year
ORDER BY n1.n_name,
         n2.n_name,
         l_year;