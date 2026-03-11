WITH people_with_name AS
  (SELECT id,
          name
   FROM name
   WHERE name LIKE '%Bert%')
SELECT MIN(pwn.name)
FROM people_with_name AS pwn
JOIN cast_info AS ci ON pwn.id = ci.person_id
WHERE EXISTS
    (SELECT 1
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = ci.movie_id
       AND k.keyword = 'character-name-in-title')
  AND EXISTS
    (SELECT 1
     FROM movie_companies mc
     WHERE mc.movie_id = ci.movie_id);