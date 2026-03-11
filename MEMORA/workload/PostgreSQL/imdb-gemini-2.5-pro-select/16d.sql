
SELECT MIN(an.name),
       MIN(t.title)
FROM aka_name AS an
JOIN cast_info AS ci ON an.person_id = ci.person_id
JOIN title AS t ON ci.movie_id = t.id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
WHERE k.keyword = 'character-name-in-title'
  AND cn.country_code = '[us]'
  AND t.episode_nr >= 5
  AND t.episode_nr < 100;