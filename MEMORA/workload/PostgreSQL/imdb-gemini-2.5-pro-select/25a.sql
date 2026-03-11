
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS male_writer,
       MIN(t.title) AS violent_movie_title
FROM info_type AS it1
JOIN movie_info AS mi ON it1.id = mi.info_type_id
JOIN title AS t ON mi.movie_id = t.id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN name AS n ON ci.person_id = n.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE it1.info = 'genres'
  AND mi.info = 'Horror'
  AND k.keyword IN ('murder', 'blood', 'gore', 'death', 'female-nudity')
  AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)')
  AND n.gender = 'm'
  AND it2.info = 'votes';