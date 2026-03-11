
SELECT MIN(an.name),
       MIN(chn.name),
       MIN(t.title)
FROM role_type AS rt
JOIN cast_info AS ci ON rt.id = ci.role_id
JOIN name AS n ON ci.person_id = n.id
JOIN aka_name AS an ON n.id = an.person_id
JOIN title AS t ON ci.movie_id = t.id
JOIN char_name AS chn ON ci.person_role_id = chn.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
WHERE rt.role = 'actress'
  AND n.gender = 'f'
  AND n.name LIKE '%Ang%'
  AND t.production_year BETWEEN 2005 AND 2015
  AND ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)')
  AND cn.country_code = '[us]'
  AND mc.note IS NOT NULL
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%');