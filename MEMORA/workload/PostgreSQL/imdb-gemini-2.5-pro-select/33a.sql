
SELECT MIN(cn1.name),
       MIN(cn2.name),
       MIN(mi_idx1.info),
       MIN(mi_idx2.info),
       MIN(t1.title),
       MIN(t2.title)
FROM movie_link AS ml
JOIN link_type AS lt ON ml.link_type_id = lt.id
AND lt.link IN ('sequel', 'follows', 'followed by')
JOIN title AS t1 ON ml.movie_id = t1.id
JOIN title AS t2 ON ml.linked_movie_id = t2.id
AND t2.production_year BETWEEN 2005 AND 2008
JOIN kind_type AS kt1 ON t1.kind_id = kt1.id
AND kt1.kind IN ('tv series')
JOIN kind_type AS kt2 ON t2.kind_id = kt2.id
AND kt2.kind IN ('tv series')
JOIN movie_info_idx AS mi_idx1 ON t1.id = mi_idx1.movie_id
JOIN movie_info_idx AS mi_idx2 ON t2.id = mi_idx2.movie_id
AND mi_idx2.info < '3.0'
JOIN info_type AS it1 ON mi_idx1.info_type_id = it1.id
AND it1.info = 'rating'
JOIN info_type AS it2 ON mi_idx2.info_type_id = it2.id
AND it2.info = 'rating'
JOIN movie_companies AS mc1 ON t1.id = mc1.movie_id
JOIN movie_companies AS mc2 ON t2.id = mc2.movie_id
JOIN company_name AS cn1 ON mc1.company_id = cn1.id
AND cn1.country_code = '[us]'
JOIN company_name AS cn2 ON mc2.company_id = cn2.id;