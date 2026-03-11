WITH filtered_customers AS
  (SELECT c_custkey
   FROM customer
   WHERE c_mktsegment = 'BUILDING'),
     filtered_orders AS
  (SELECT o_orderkey,
          o_custkey,
          o_orderdate,
          o_shippriority
   FROM orders
   WHERE o_orderdate < DATE '1995-03-15'),
     filtered_lineitems AS
  (SELECT l_orderkey,
          l_extendedprice,
          l_discount
   FROM lineitem
   WHERE l_shipdate > DATE '1995-03-15')
SELECT fl.l_orderkey,
       sum(fl.l_extendedprice * (1 - fl.l_discount)) AS revenue,
       fo.o_orderdate,
       fo.o_shippriority
FROM filtered_customers fc
JOIN filtered_orders fo ON fc.c_custkey = fo.o_custkey
JOIN filtered_lineitems fl ON fo.o_orderkey = fl.l_orderkey
GROUP BY fl.l_orderkey,
         fo.o_orderdate,
         fo.o_shippriority
ORDER BY revenue DESC,
         fo.o_orderdate
LIMIT 10;