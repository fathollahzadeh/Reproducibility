
SELECT MIN(an.name) AS alternative_name,
       MIN(chn.name) AS voiced_character,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS american_movie
FROM title AS t
INNER JOIN movie_companies AS mc ON t.id = mc.movie_id
INNER JOIN company_name AS cn ON mc.company_id = cn.id
INNER JOIN cast_info AS ci ON t.id = ci.movie_id
INNER JOIN role_type AS rt ON ci.role_id = rt.id
INNER JOIN name AS n ON ci.person_id = n.id
INNER JOIN aka_name AS an ON n.id = an.person_id
INNER JOIN char_name AS chn ON ci.person_role_id = chn.id
WHERE ci.note = '(voice)'
  AND cn.country_code = '[us]'
  AND mc.note LIKE '%(200%)%'
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%')
  AND n.gender = 'f'
  AND n.name LIKE '%Angel%'
  AND rt.role = 'actress'
  AND t.production_year BETWEEN 2007 AND 2010;