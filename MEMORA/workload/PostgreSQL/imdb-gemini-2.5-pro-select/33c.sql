WITH t1_ids AS
  (SELECT t.id
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE kt.kind IN ('tv series', 'episode')),
     t2_ids AS
  (SELECT t.id
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE t.production_year BETWEEN 2000 AND 2010
     AND kt.kind IN ('tv series', 'episode'))
SELECT MIN(cn1.name),
       MIN(cn2.name),
       MIN(mi_idx1.info),
       MIN(mi_idx2.info),
       MIN(t1.title),
       MIN(t2.title)
FROM movie_link AS ml
JOIN link_type AS lt ON ml.link_type_id = lt.id
JOIN t1_ids ON ml.movie_id = t1_ids.id
JOIN t2_ids ON ml.linked_movie_id = t2_ids.id
JOIN title AS t1 ON t1.id = t1_ids.id
JOIN title AS t2 ON t2.id = t2_ids.id
JOIN movie_info_idx AS mi_idx1 ON t1.id = mi_idx1.movie_id
JOIN info_type AS it1 ON mi_idx1.info_type_id = it1.id
JOIN movie_companies AS mc1 ON t1.id = mc1.movie_id
JOIN company_name AS cn1 ON mc1.company_id = cn1.id
JOIN movie_info_idx AS mi_idx2 ON t2.id = mi_idx2.movie_id
JOIN info_type AS it2 ON mi_idx2.info_type_id = it2.id
JOIN movie_companies AS mc2 ON t2.id = mc2.movie_id
JOIN company_name AS cn2 ON mc2.company_id = cn2.id
WHERE lt.link IN ('sequel', 'follows', 'followed by')
  AND cn1.country_code != '[us]'
  AND it1.info = 'rating'
  AND it2.info = 'rating'
  AND mi_idx2.info < '3.5';