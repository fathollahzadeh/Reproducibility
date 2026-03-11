
SELECT MIN(mi.info),
       MIN(mi_idx.info),
       MIN(t.title)
FROM title AS t
JOIN
  (SELECT ci.movie_id
   FROM cast_info AS ci
   JOIN name AS n ON ci.person_id = n.id
   WHERE n.gender = 'm'
     AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)')
   GROUP BY ci.movie_id) AS valid_cast ON t.id = valid_cast.movie_id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War')
  AND it1.info = 'genres'
  AND it2.info = 'votes';