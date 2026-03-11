WITH filtered_ci AS
  (SELECT ci.movie_id,
          ci.person_id,
          ci.person_role_id
   FROM cast_info AS ci
   JOIN role_type AS rt ON ci.role_id = rt.id
   WHERE ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)')
     AND rt.role = 'actress')
SELECT MIN(chn.name) AS voiced_char,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS voiced_animation
FROM filtered_ci
JOIN title AS t ON t.id = filtered_ci.movie_id
AND t.production_year BETWEEN 2000 AND 2010
JOIN name AS n ON n.id = filtered_ci.person_id
AND n.gender = 'f'
AND n.name LIKE '%An%'
JOIN char_name AS chn ON chn.id = filtered_ci.person_role_id
WHERE EXISTS
    (SELECT 1
     FROM aka_name
     WHERE person_id = filtered_ci.person_id)
  AND EXISTS
    (SELECT 1
     FROM person_info AS pi
     JOIN info_type AS it3 ON it3.id = pi.info_type_id
     WHERE pi.person_id = filtered_ci.person_id
       AND it3.info = 'trivia')
  AND EXISTS
    (SELECT 1
     FROM movie_keyword AS mk
     JOIN keyword AS k ON k.id = mk.keyword_id
     WHERE mk.movie_id = filtered_ci.movie_id
       AND k.keyword = 'computer-animation')
  AND EXISTS
    (SELECT 1
     FROM movie_companies AS mc
     JOIN company_name AS cn ON cn.id = mc.company_id
     WHERE mc.movie_id = filtered_ci.movie_id
       AND cn.country_code = '[us]')
  AND EXISTS
    (SELECT 1
     FROM movie_info AS mi
     JOIN info_type AS it ON it.id = mi.info_type_id
     WHERE mi.movie_id = filtered_ci.movie_id
       AND it.info = 'release dates'
       AND (mi.info LIKE 'Japan:%200%'
            OR mi.info LIKE 'USA:%200%'))
  AND EXISTS
    (SELECT 1
     FROM complete_cast AS cc
     JOIN comp_cast_type AS cct1 ON cct1.id = cc.subject_id
     JOIN comp_cast_type AS cct2 ON cct2.id = cc.status_id
     WHERE cc.movie_id = filtered_ci.movie_id
       AND cct1.kind = 'cast'
       AND cct2.kind = 'complete+verified');