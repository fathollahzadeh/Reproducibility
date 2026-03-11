
SELECT MIN(an1.name) AS actress_pseudonym,
       MIN(t.title) AS japanese_movie_dubbed
FROM company_name AS cn
JOIN movie_companies AS mc ON mc.company_id = cn.id
JOIN title AS t ON mc.movie_id = t.id
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN role_type AS rt ON ci.role_id = rt.id
JOIN name AS n1 ON ci.person_id = n1.id
JOIN aka_name AS an1 ON an1.person_id = n1.id
WHERE cn.country_code = '[jp]'
  AND mc.note LIKE '%(Japan)%'
  AND mc.note NOT LIKE '%(USA)%'
  AND rt.role = 'actress'
  AND n1.name LIKE '%Yo%'
  AND n1.name NOT LIKE '%Yu%'
  AND ci.note = '(voice: English version)';