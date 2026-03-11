
SELECT c.c_name,
       c.c_custkey,
       o.o_orderkey,
       o.o_orderdate,
       o.o_totalprice,
       l_agg.total_quantity
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN LATERAL
  (SELECT SUM(l.l_quantity) AS total_quantity
   FROM lineitem l
   WHERE l.l_orderkey = o.o_orderkey) l_agg ON l_agg.total_quantity > 300
ORDER BY o.o_totalprice DESC,
         o.o_orderdate
LIMIT 100;