
SELECT MIN(mc.note) AS production_note,
       MIN(t.title) AS movie_title,
       MIN(t.production_year) AS movie_year
FROM info_type AS it
JOIN movie_info_idx AS mi_idx ON it.id = mi_idx.info_type_id
JOIN title AS t ON t.id = mi_idx.movie_id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_type AS ct ON ct.id = mc.company_type_id
WHERE it.info = 'top 250 rank'
  AND ct.kind = 'production companies'
  AND mc.note NOT LIKE '%(as Metro-Goldwyn-Mayer Pictures)%'
  AND (mc.note LIKE '%(co-production)%'
       OR mc.note LIKE '%(presents)%');