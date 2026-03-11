
SELECT MIN(k.keyword),
       MIN(n.name),
       MIN(t.title)
FROM
  (SELECT id,
          title
   FROM title
   WHERE production_year > 2014) AS t
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN
  (SELECT id,
          keyword
   FROM keyword
   WHERE keyword IN ('superhero', 'sequel', 'second-part', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence')) AS k ON mk.keyword_id = k.id
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN
  (SELECT id,
          name
   FROM name
   WHERE name LIKE '%Downey%Robert%') AS n ON ci.person_id = n.id;