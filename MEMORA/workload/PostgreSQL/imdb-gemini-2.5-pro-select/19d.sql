
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS jap_engl_voiced_movie
FROM role_type AS rt
JOIN cast_info AS ci ON rt.id = ci.role_id
JOIN name AS n ON ci.person_id = n.id
JOIN title AS t ON ci.movie_id = t.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it ON mi.info_type_id = it.id
WHERE rt.role = 'actress'
  AND n.gender = 'f'
  AND t.production_year > 2000
  AND cn.country_code = '[us]'
  AND it.info = 'release dates'
  AND ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)')
  AND EXISTS
    (SELECT 1
     FROM char_name AS chn
     WHERE chn.id = ci.person_role_id)
  AND EXISTS
    (SELECT 1
     FROM aka_name AS an
     WHERE an.person_id = n.id);