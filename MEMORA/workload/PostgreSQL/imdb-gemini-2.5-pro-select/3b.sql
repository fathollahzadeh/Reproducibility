
SELECT MIN(t.title) AS movie_title
FROM title AS t
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN movie_info AS mi ON t.id = mi.movie_id
WHERE t.production_year > 2010
  AND k.keyword LIKE '%sequel%'
  AND mi.info IN ('Bulgaria');