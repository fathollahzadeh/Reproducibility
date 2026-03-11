
SELECT MIN(t.title)
FROM keyword AS k
JOIN movie_keyword AS mk ON k.id = mk.keyword_id
JOIN title AS t ON mk.movie_id = t.id
JOIN movie_info AS mi ON t.id = mi.movie_id
WHERE k.keyword LIKE '%sequel%'
  AND t.production_year > 2005
  AND mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German');