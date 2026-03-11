
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS voiced_movie
FROM name AS n
JOIN cast_info AS ci ON n.id = ci.person_id
JOIN title AS t ON ci.movie_id = t.id
WHERE n.gender = 'f'
  AND n.name LIKE '%Ang%'
  AND ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)')
  AND t.production_year BETWEEN 2005 AND 2009
  AND EXISTS
    (SELECT 1
     FROM aka_name an
     WHERE an.person_id = n.id)
  AND EXISTS
    (SELECT 1
     FROM char_name chn
     WHERE chn.id = ci.person_role_id)
  AND EXISTS
    (SELECT 1
     FROM role_type rt
     WHERE rt.id = ci.role_id
       AND rt.role = 'actress')
  AND EXISTS
    (SELECT 1
     FROM movie_companies mc
     JOIN company_name cn ON mc.company_id = cn.id
     WHERE mc.movie_id = t.id
       AND cn.country_code = '[us]'
       AND (mc.note LIKE '%(USA)%'
            OR mc.note LIKE '%(worldwide)%'))
  AND EXISTS
    (SELECT 1
     FROM movie_info mi
     JOIN info_type it ON mi.info_type_id = it.id
     WHERE mi.movie_id = t.id
       AND it.info = 'release dates'
       AND (mi.info LIKE 'Japan:%200%'
            OR mi.info LIKE 'USA:%200%'));