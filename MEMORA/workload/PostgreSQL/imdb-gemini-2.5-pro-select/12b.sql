
SELECT MIN(mi.info) AS budget,
       MIN(t.title) AS unsuccsessful_movie
FROM title AS t
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
WHERE t.production_year > 2000
  AND (t.title LIKE 'Birdemic%'
       OR t.title LIKE '%Movie%')
  AND it1.info = 'budget'
  AND EXISTS
    (SELECT 1
     FROM movie_info_idx AS mi_idx
     JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
     WHERE mi_idx.movie_id = t.id
       AND it2.info = 'bottom 10 rank')
  AND EXISTS
    (SELECT 1
     FROM movie_companies AS mc
     JOIN company_name AS cn ON mc.company_id = cn.id
     JOIN company_type AS ct ON mc.company_type_id = ct.id
     WHERE mc.movie_id = t.id
       AND cn.country_code = '[us]'
       AND ct.kind IN ('production companies','distributors'));