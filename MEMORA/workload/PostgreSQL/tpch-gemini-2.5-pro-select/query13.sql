
SELECT c_orders.c_count,
       count(*) AS custdist
FROM
  (SELECT c.c_custkey,
          coalesce(o.o_count, 0) AS c_count
   FROM customer c
   LEFT JOIN
     (SELECT o_custkey,
             count(*) AS o_count
      FROM orders
      WHERE o_comment NOT LIKE '%special%requests%'
      GROUP BY o_custkey) o ON c.c_custkey = o.o_custkey) AS c_orders
GROUP BY c_orders.c_count
ORDER BY custdist DESC,
         c_count DESC;