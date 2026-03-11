WITH valid_partsupp AS
  (SELECT ps.ps_partkey,
          ps.ps_suppkey
   FROM partsupp ps
   WHERE NOT EXISTS
       (SELECT 1
        FROM supplier s
        WHERE s.s_suppkey = ps.ps_suppkey
          AND s.s_comment LIKE '%Customer%Complaints%'))
SELECT p.p_brand,
       p.p_type,
       p.p_size,
       COUNT(DISTINCT vps.ps_suppkey) AS supplier_cnt
FROM valid_partsupp vps
JOIN part p ON vps.ps_partkey = p.p_partkey
WHERE p.p_brand <> 'Brand#45'
  AND p.p_type NOT LIKE 'MEDIUM POLISHED%'
  AND p.p_size IN ('49', '14', '23', '45', '19', '3', '36', '9')
GROUP BY p.p_brand,
         p.p_type,
         p.p_size
ORDER BY supplier_cnt DESC,
         p.p_brand,
         p.p_type,
         p.p_size;