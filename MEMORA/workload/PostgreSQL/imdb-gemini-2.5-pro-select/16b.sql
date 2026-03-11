
SELECT MIN(an.name),
       MIN(t.title)
FROM aka_name AS an
JOIN name AS n ON n.id = an.person_id
JOIN cast_info AS ci ON ci.person_id = n.id
JOIN title AS t ON t.id = ci.movie_id
WHERE t.id IN
    (SELECT movie_id
     FROM movie_keyword mk
     JOIN keyword k ON k.id = mk.keyword_id
     WHERE k.keyword = 'character-name-in-title')
  AND t.id IN
    (SELECT movie_id
     FROM movie_companies mc
     JOIN company_name cn ON cn.id = mc.company_id
     WHERE cn.country_code = '[us]');