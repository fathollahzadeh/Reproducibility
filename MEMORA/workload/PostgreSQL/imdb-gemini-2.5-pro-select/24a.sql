WITH qualifying_movies AS
  (SELECT t.id AS movie_id,
          t.title
   FROM title AS t
   WHERE t.production_year > 2010
     AND EXISTS
       (SELECT 1
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        WHERE mk.movie_id = t.id
          AND k.keyword IN ('hero', 'martial-arts', 'hand-to-hand-combat'))
     AND EXISTS
       (SELECT 1
        FROM movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        WHERE mc.movie_id = t.id
          AND cn.country_code = '[us]')
     AND EXISTS
       (SELECT 1
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE mi.movie_id = t.id
          AND it.info = 'release dates'
          AND (mi.info LIKE 'Japan:%201%'
               OR mi.info LIKE 'USA:%201%')))
SELECT MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress_name,
       MIN(qm.title) AS voiced_action_movie_jap_eng
FROM qualifying_movies AS qm
JOIN cast_info AS ci ON qm.movie_id = ci.movie_id
JOIN name AS n ON ci.person_id = n.id
JOIN role_type AS rt ON ci.role_id = rt.id
JOIN char_name AS chn ON ci.person_role_id = chn.id
JOIN aka_name AS an ON n.id = an.person_id
WHERE ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)')
  AND n.gender = 'f'
  AND n.name LIKE '%An%'
  AND rt.role = 'actress';