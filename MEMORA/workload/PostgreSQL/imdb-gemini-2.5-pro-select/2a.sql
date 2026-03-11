WITH movie_ids AS
  (SELECT mc.movie_id
   FROM movie_companies AS mc
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE cn.country_code = '[de]' INTERSECT
     SELECT mk.movie_id
     FROM movie_keyword AS mk
     JOIN keyword AS k ON mk.keyword_id = k.id WHERE k.keyword = 'character-name-in-title')
SELECT MIN(t.title)
FROM title AS t
JOIN movie_ids ON t.id = movie_ids.movie_id;