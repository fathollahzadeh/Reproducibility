WITH regional_parts_suppliers AS
  (SELECT s.s_acctbal,
          s.s_name,
          n.n_name,
          p.p_partkey,
          p.p_mfgr,
          s.s_address,
          s.s_phone,
          s.s_comment,
          RANK() OVER (
                       ORDER BY ps.ps_supplycost) AS cost_rank
   FROM region AS r
   INNER JOIN nation AS n ON r.r_regionkey = n.n_regionkey
   INNER JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
   INNER JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
   INNER JOIN part AS p ON ps.ps_partkey = p.p_partkey
   WHERE r.r_name = 'EUROPE'
     AND p.p_size = 15
     AND p.p_type LIKE '%BRASS')
SELECT s_acctbal,
       s_name,
       n_name,
       p_partkey,
       p_mfgr,
       s_address,
       s_phone,
       s_comment
FROM regional_parts_suppliers
WHERE cost_rank = 1
ORDER BY s_acctbal DESC,
         n_name,
         s_name,
         p_partkey
LIMIT 100;