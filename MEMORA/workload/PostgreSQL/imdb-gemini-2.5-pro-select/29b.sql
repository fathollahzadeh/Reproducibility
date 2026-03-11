
SELECT MIN(chn.name) AS voiced_char,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS voiced_animation
FROM name AS n
JOIN cast_info AS ci ON n.id = ci.person_id
JOIN title AS t ON ci.movie_id = t.id
JOIN char_name AS chn ON chn.id = ci.person_role_id
JOIN role_type AS rt ON rt.id = ci.role_id
JOIN aka_name AS an ON an.person_id = n.id
JOIN person_info AS pi ON pi.person_id = n.id
JOIN info_type AS it3 ON pi.info_type_id = it3.id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it ON mi.info_type_id = it.id
JOIN complete_cast AS cc ON t.id = cc.movie_id
JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
WHERE t.production_year BETWEEN 2000 AND 2005
  AND t.title = 'Shrek 2'
  AND n.gender = 'f'
  AND n.name LIKE '%An%'
  AND chn.name = 'Queen'
  AND ci.note IN ('(voice)', '(voice) (uncredited)', '(voice: English version)')
  AND rt.role = 'actress'
  AND it3.info = 'height'
  AND k.keyword = 'computer-animation'
  AND cn.country_code = '[us]'
  AND it.info = 'release dates'
  AND mi.info LIKE 'USA:%200%'
  AND cct1.kind = 'cast'
  AND cct2.kind = 'complete+verified';