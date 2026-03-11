WITH cust_filtered AS
  (SELECT c_custkey,
          c_acctbal,
          substring(c_phone
                    FROM 1
                    FOR 2) AS cntrycode,
          AVG(CASE
                  WHEN c_acctbal > 0.0 THEN c_acctbal
              END) OVER () AS avg_acctbal
   FROM customer
   WHERE substring(c_phone
                   FROM 1
                   FOR 2) IN ('13',
                              '31',
                              '23',
                              '29',
                              '30',
                              '18',
                              '17'))
SELECT cf.cntrycode,
       COUNT(*) AS numcust,
       SUM(cf.c_acctbal) AS totacctbal
FROM cust_filtered cf
LEFT JOIN orders o ON cf.c_custkey = o.o_custkey
WHERE cf.c_acctbal > cf.avg_acctbal
  AND o.o_orderkey IS NULL
GROUP BY cf.cntrycode
ORDER BY cf.cntrycode;