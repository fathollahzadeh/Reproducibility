
SELECT ps_partkey,
       value
FROM
  (SELECT ps_partkey,
          sum(ps_supplycost * ps_availqty) AS value,
          sum(sum(ps_supplycost * ps_availqty)) OVER () AS total_value
   FROM partsupp
   JOIN supplier ON ps_suppkey = s_suppkey
   JOIN nation ON s_nationkey = n_nationkey
   WHERE n_name = 'GERMANY'
   GROUP BY ps_partkey) AS grouped_values
WHERE value > total_value * 0.0001
ORDER BY value DESC;