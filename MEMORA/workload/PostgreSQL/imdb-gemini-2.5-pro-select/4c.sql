
SELECT MIN(mi_idx.info) AS rating,
       MIN(t.title) AS movie_title
FROM title AS t
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
WHERE t.production_year > 1990
  AND mi_idx.info > '2.0'
  AND mi_idx.info_type_id IN
    (SELECT id
     FROM info_type
     WHERE info = 'rating')
  AND t.id IN
    (SELECT mk.movie_id
     FROM movie_keyword AS mk
     JOIN keyword AS k ON mk.keyword_id = k.id
     WHERE k.keyword LIKE '%sequel%');