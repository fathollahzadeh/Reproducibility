
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS mainstream_movie
FROM title AS t
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE t.production_year BETWEEN 2000 AND 2010
  AND cn.country_code = '[us]'
  AND ct.kind = 'production companies'
  AND it2.info = 'rating'
  AND mi_idx.info > '7.0'
  AND t.id IN
    (SELECT mi.movie_id
     FROM movie_info AS mi
     JOIN info_type AS it1 ON mi.info_type_id = it1.id
     WHERE it1.info = 'genres'
       AND mi.info IN ('Drama', 'Horror', 'Western', 'Family'));