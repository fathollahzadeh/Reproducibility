
SELECT MIN(n.name) AS member_in_charnamed_movie,
       MIN(n.name) AS a1
FROM name AS n
JOIN cast_info AS ci ON n.id = ci.person_id
WHERE n.name LIKE 'Z%'
  AND EXISTS
    (SELECT 1
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = ci.movie_id
       AND k.keyword = 'character-name-in-title')
  AND EXISTS
    (SELECT 1
     FROM movie_companies mc
     JOIN company_name cn ON mc.company_id = cn.id
     WHERE mc.movie_id = ci.movie_id);