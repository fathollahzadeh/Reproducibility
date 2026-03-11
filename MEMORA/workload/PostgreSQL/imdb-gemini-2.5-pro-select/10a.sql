
SELECT MIN(chn.name) AS uncredited_voiced_character,
       MIN(t.title) AS russian_movie
FROM company_name AS cn
JOIN movie_companies AS mc ON cn.id = mc.company_id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN title AS t ON mc.movie_id = t.id
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN role_type AS rt ON ci.role_id = rt.id
JOIN char_name AS chn ON ci.person_role_id = chn.id
WHERE cn.country_code = '[ru]'
  AND t.production_year > 2005
  AND rt.role = 'actor'
  AND ci.note LIKE '%(voice)%'
  AND ci.note LIKE '%(uncredited)%';