
SELECT MIN(cn1.name) AS first_company,
       MIN(cn2.name) AS second_company,
       MIN(mi_idx1.info) AS first_rating,
       MIN(mi_idx2.info) AS second_rating,
       MIN(t1.title) AS first_movie,
       MIN(t2.title) AS second_movie
FROM movie_link AS ml
JOIN
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE kt.kind IN ('tv series')) AS t1 ON ml.movie_id = t1.id
JOIN
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE t.production_year = 2007
     AND kt.kind IN ('tv series')) AS t2 ON ml.linked_movie_id = t2.id
JOIN link_type AS lt ON ml.link_type_id = lt.id
AND lt.link LIKE '%follow%'
JOIN
  (SELECT mi.movie_id,
          mi.info
   FROM movie_info_idx AS mi
   JOIN info_type AS it ON mi.info_type_id = it.id
   WHERE it.info = 'rating') AS mi_idx1 ON t1.id = mi_idx1.movie_id
JOIN
  (SELECT mi.movie_id,
          mi.info
   FROM movie_info_idx AS mi
   JOIN info_type AS it ON mi.info_type_id = it.id
   WHERE it.info = 'rating'
     AND mi.info < '3.0') AS mi_idx2 ON t2.id = mi_idx2.movie_id
JOIN movie_companies AS mc1 ON t1.id = mc1.movie_id
JOIN company_name AS cn1 ON mc1.company_id = cn1.id
AND cn1.country_code = '[nl]'
JOIN movie_companies AS mc2 ON t2.id = mc2.movie_id
JOIN company_name AS cn2 ON mc2.company_id = cn2.id;