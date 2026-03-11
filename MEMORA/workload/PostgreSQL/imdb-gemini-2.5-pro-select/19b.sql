WITH filtered_titles AS
  (SELECT t.id,
          t.title
   FROM title AS t
   WHERE t.production_year BETWEEN 2007 AND 2008
     AND t.title LIKE '%Kung%Fu%Panda%'),
     filtered_names AS
  (SELECT n.id,
          n.name
   FROM name AS n
   WHERE n.gender = 'f'
     AND n.name LIKE '%Angel%')
SELECT MIN(fn.name) AS voicing_actress,
       MIN(ft.title) AS kung_fu_panda
FROM filtered_titles AS ft
JOIN movie_companies AS mc ON ft.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN movie_info AS mi ON ft.id = mi.movie_id
JOIN info_type AS it ON mi.info_type_id = it.id
JOIN cast_info AS ci ON ft.id = ci.movie_id
JOIN filtered_names AS fn ON ci.person_id = fn.id
JOIN role_type AS rt ON ci.role_id = rt.id
WHERE ci.note = '(voice)'
  AND cn.country_code = '[us]'
  AND it.info = 'release dates'
  AND mc.note LIKE '%(200%)%'
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%')
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'Japan:%2007%'
       OR mi.info LIKE 'USA:%2008%')
  AND rt.role = 'actress'
  AND EXISTS
    (SELECT 1
     FROM aka_name an
     WHERE an.person_id = fn.id)
  AND EXISTS
    (SELECT 1
     FROM char_name chn
     WHERE chn.id = ci.person_role_id);