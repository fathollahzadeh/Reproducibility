
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS writer,
       MIN(t.title) AS complete_violent_movie
FROM title AS t
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN complete_cast AS cc ON t.id = cc.movie_id
JOIN name AS n ON ci.person_id = n.id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
WHERE cct1.kind IN ('cast', 'crew')
  AND cct2.kind = 'complete+verified'
  AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital')
  AND mi.info IN ('Horror', 'Thriller')
  AND n.gender = 'm'
  AND t.production_year > 2000;