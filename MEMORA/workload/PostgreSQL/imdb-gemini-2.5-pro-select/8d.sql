
SELECT MIN(an1.name) AS costume_designer_pseudo,
       MIN(t.title) AS movie_with_costumes
FROM role_type AS rt
JOIN cast_info AS ci ON rt.id = ci.role_id
JOIN aka_name AS an1 ON ci.person_id = an1.person_id
JOIN title AS t ON ci.movie_id = t.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
WHERE rt.role = 'costume designer'
  AND cn.country_code = '[us]';