
SELECT MIN(k.keyword),
       MIN(n.name),
       MIN(t.title)
FROM title AS t
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN name AS n ON ci.person_id = n.id
WHERE t.production_year > 2000
  AND n.name LIKE '%Downey%Robert%'
  AND k.keyword IN ('superhero', 'sequel', 'second-part', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence');