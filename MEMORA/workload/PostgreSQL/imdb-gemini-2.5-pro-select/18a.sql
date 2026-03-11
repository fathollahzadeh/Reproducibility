
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(t.title) AS movie_title
FROM title AS t
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE it1.info = 'budget'
  AND it2.info = 'votes'
  AND t.id IN
    (SELECT ci.movie_id
     FROM cast_info AS ci
     JOIN name AS n ON ci.person_id = n.id
     WHERE n.gender = 'm'
       AND n.name LIKE '%Tim%'
       AND ci.note IN ('(producer)', '(executive producer)'));