
SELECT MIN(n.name)
FROM name AS n
JOIN cast_info AS ci ON n.id = ci.person_id
WHERE ci.movie_id IN
    (SELECT mk.movie_id
     FROM keyword AS k
     JOIN movie_keyword AS mk ON k.id = mk.keyword_id
     JOIN movie_companies AS mc ON mk.movie_id = mc.movie_id
     JOIN company_name AS cn ON mc.company_id = cn.id
     WHERE k.keyword = 'character-name-in-title'
       AND cn.country_code = '[us]');