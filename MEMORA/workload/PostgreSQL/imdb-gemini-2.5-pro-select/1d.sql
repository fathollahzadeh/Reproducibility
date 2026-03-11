
SELECT MIN(mc.note) AS production_note,
       MIN(t.title) AS movie_title,
       MIN(t.production_year) AS movie_year
FROM title AS t
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN info_type AS it ON mi_idx.info_type_id = it.id
WHERE t.production_year > 2000
  AND ct.kind = 'production companies'
  AND it.info = 'bottom 10 rank'
  AND mc.note NOT LIKE '%(as Metro-Goldwyn-Mayer Pictures)%';