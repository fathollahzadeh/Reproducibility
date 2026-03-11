WITH movie_pool AS
  (SELECT id,
          title
   FROM title
   WHERE production_year BETWEEN 2005 AND 2008)
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(mp.title) AS drama_horror_movie
FROM movie_pool AS mp
JOIN movie_info AS mi ON mp.id = mi.movie_id
JOIN movie_info_idx AS mi_idx ON mp.id = mi_idx.movie_id
JOIN movie_companies AS mc ON mp.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE cn.country_code = '[us]'
  AND ct.kind = 'production companies'
  AND it1.info = 'genres'
  AND it2.info = 'rating'
  AND mi.info IN ('Drama', 'Horror')
  AND mi_idx.info > '8.0';