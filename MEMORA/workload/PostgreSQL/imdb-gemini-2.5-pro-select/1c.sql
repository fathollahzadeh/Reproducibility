WITH filtered_mc AS
  (SELECT mc.movie_id,
          mc.note
   FROM movie_companies AS mc
   JOIN company_type AS ct ON mc.company_type_id = ct.id
   WHERE ct.kind = 'production companies'
     AND mc.note NOT LIKE '%(as Metro-Goldwyn-Mayer Pictures)%'
     AND mc.note LIKE '%(co-production)%'),
     filtered_mi_idx AS
  (SELECT mi_idx.movie_id
   FROM movie_info_idx AS mi_idx
   JOIN info_type AS it ON mi_idx.info_type_id = it.id
   WHERE it.info = 'top 250 rank')
SELECT MIN(mc.note),
       MIN(t.title),
       MIN(t.production_year)
FROM title AS t
JOIN filtered_mc AS mc ON t.id = mc.movie_id
JOIN filtered_mi_idx AS mi_idx ON t.id = mi_idx.movie_id
WHERE t.production_year > 2010;