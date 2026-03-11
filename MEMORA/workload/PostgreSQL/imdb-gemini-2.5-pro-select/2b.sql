
SELECT MIN(t.title)
FROM title AS t
JOIN
  (SELECT mc.movie_id
   FROM movie_companies AS mc
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE cn.country_code = '[nl]') AS cm ON t.id = cm.movie_id
JOIN
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword = 'character-name-in-title') AS km ON t.id = km.movie_id;