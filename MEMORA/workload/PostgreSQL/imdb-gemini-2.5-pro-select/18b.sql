WITH filtered_cast AS
  (SELECT ci.movie_id
   FROM cast_info AS ci
   JOIN name AS n ON ci.person_id = n.id
   WHERE n.gender = 'f'
     AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)'))
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(t.title) AS movie_title
FROM title AS t
JOIN filtered_cast AS fc ON t.id = fc.movie_id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE t.production_year BETWEEN 2008 AND 2014
  AND it1.info = 'genres'
  AND mi.info IN ('Horror', 'Thriller')
  AND mi.note IS NULL
  AND it2.info = 'rating'
  AND mi_idx.info > '8.0';