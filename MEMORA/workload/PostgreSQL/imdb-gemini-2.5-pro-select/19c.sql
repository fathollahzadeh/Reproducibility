
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS jap_engl_voiced_movie
FROM cast_info AS ci
JOIN name AS n ON n.id = ci.person_id
JOIN title AS t ON t.id = ci.movie_id
JOIN role_type AS rt ON rt.id = ci.role_id
JOIN char_name AS chn ON chn.id = ci.person_role_id
JOIN aka_name AS an ON an.person_id = n.id
WHERE ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)')
  AND n.gender = 'f'
  AND n.name LIKE '%An%'
  AND t.production_year > 2000
  AND rt.role = 'actress'
  AND EXISTS
    (SELECT 1
     FROM movie_companies AS mc
     JOIN company_name AS cn ON mc.company_id = cn.id
     WHERE mc.movie_id = t.id
       AND cn.country_code = '[us]')
  AND EXISTS
    (SELECT 1
     FROM movie_info AS mi
     JOIN info_type AS it ON mi.info_type_id = it.id
     WHERE mi.movie_id = t.id
       AND it.info = 'release dates'
       AND (mi.info LIKE 'Japan:%200%'
            OR mi.info LIKE 'USA:%200%'));