
SELECT sum(l_extendedprice) / 7.0 AS avg_yearly
FROM
  (SELECT l_extendedprice,
          l_quantity,
          0.2 * AVG(l_quantity) OVER (PARTITION BY l_partkey) AS avg_qty_threshold
   FROM lineitem
   JOIN part ON p_partkey = l_partkey
   WHERE p_brand = 'Brand#23'
     AND p_container = 'MED BOX') AS subquery
WHERE l_quantity < avg_qty_threshold;