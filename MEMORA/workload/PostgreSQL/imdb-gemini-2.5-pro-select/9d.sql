
SELECT MIN(an.name) AS alternative_name,
       MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS american_movie
FROM name AS n
JOIN aka_name AS an ON an.person_id = n.id
JOIN cast_info AS ci ON ci.person_id = n.id
JOIN title AS t ON ci.movie_id = t.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN role_type AS rt ON ci.role_id = rt.id
JOIN char_name AS chn ON ci.person_role_id = chn.id
WHERE n.gender = 'f'
  AND ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)')
  AND cn.country_code = '[us]'
  AND rt.role = 'actress';