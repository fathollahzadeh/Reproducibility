WITH cast_movies AS
  (SELECT ci.movie_id,
          MIN(n.name) AS min_name
   FROM cast_info AS ci
   JOIN name AS n ON ci.person_id = n.id
   WHERE n.gender = 'm'
     AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)')
   GROUP BY ci.movie_id),
     keyword_movies AS
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital')
   GROUP BY mk.movie_id)
SELECT MIN(mi.info),
       MIN(mi_idx.info),
       MIN(cm.min_name),
       MIN(t.title)
FROM title AS t
JOIN cast_movies AS cm ON t.id = cm.movie_id
JOIN keyword_movies AS km ON t.id = km.movie_id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE it1.info = 'genres'
  AND it2.info = 'votes'
  AND mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War');