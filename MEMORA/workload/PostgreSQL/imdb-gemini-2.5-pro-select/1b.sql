WITH mc_filtered AS
  (SELECT mc.movie_id,
          mc.note
   FROM movie_companies AS mc
   JOIN company_type AS ct ON mc.company_type_id = ct.id
   WHERE ct.kind = 'production companies'
     AND mc.note NOT LIKE '%(as Metro-Goldwyn-Mayer Pictures)%'),
     mi_idx_filtered AS
  (SELECT mi.movie_id
   FROM movie_info_idx AS mi
   JOIN info_type AS it ON mi.info_type_id = it.id
   WHERE it.info = 'bottom 10 rank')
SELECT MIN(mc.note),
       MIN(t.title),
       MIN(t.production_year)
FROM title AS t
JOIN mc_filtered AS mc ON t.id = mc.movie_id
JOIN mi_idx_filtered AS mi_idx ON t.id = mi_idx.movie_id
WHERE t.production_year BETWEEN 2005 AND 2010;