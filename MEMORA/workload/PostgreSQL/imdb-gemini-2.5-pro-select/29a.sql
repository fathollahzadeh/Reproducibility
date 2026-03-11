WITH movie_base AS
  (SELECT id,
          title
   FROM title
   WHERE production_year BETWEEN 2000 AND 2010
     AND title = 'Shrek 2'),
     person_base AS
  (SELECT id,
          name
   FROM name
   WHERE gender = 'f'
     AND name LIKE '%An%'),
     cast_filtered AS
  (SELECT ci.movie_id,
          ci.person_id,
          chn.name AS chn_name
   FROM cast_info AS ci
   JOIN role_type AS rt ON ci.role_id = rt.id
   AND rt.role = 'actress'
   JOIN char_name AS chn ON ci.person_role_id = chn.id
   AND chn.name = 'Queen'
   WHERE ci.note IN ('(voice)', '(voice) (uncredited)', '(voice: English version)'))
SELECT MIN(cf.chn_name),
       MIN(p.name),
       MIN(m.title)
FROM movie_base AS m
JOIN cast_filtered AS cf ON m.id = cf.movie_id
JOIN person_base AS p ON cf.person_id = p.id
WHERE EXISTS
    (SELECT 1
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = m.id
       AND k.keyword = 'computer-animation')
  AND EXISTS
    (SELECT 1
     FROM movie_companies mc
     JOIN company_name cn ON mc.company_id = cn.id
     WHERE mc.movie_id = m.id
       AND cn.country_code = '[us]')
  AND EXISTS
    (SELECT 1
     FROM movie_info mi
     JOIN info_type it ON mi.info_type_id = it.id
     WHERE mi.movie_id = m.id
       AND it.info = 'release dates'
       AND mi.info IS NOT NULL
       AND (mi.info LIKE 'Japan:%200%'
            OR mi.info LIKE 'USA:%200%'))
  AND EXISTS
    (SELECT 1
     FROM complete_cast cc
     JOIN comp_cast_type cct1 ON cc.subject_id = cct1.id
     JOIN comp_cast_type cct2 ON cc.status_id = cct2.id
     WHERE cc.movie_id = m.id
       AND cct1.kind = 'cast'
       AND cct2.kind = 'complete+verified')
  AND EXISTS
    (SELECT 1
     FROM person_info pi
     JOIN info_type it3 ON pi.info_type_id = it3.id
     WHERE pi.person_id = p.id
       AND it3.info = 'trivia')
  AND EXISTS
    (SELECT 1
     FROM aka_name an
     WHERE an.person_id = p.id);