WITH filtered_actresses AS MATERIALIZED
  (SELECT id, name
   FROM name
   WHERE gender = 'f'
     AND name LIKE '%An%'),
     filtered_movies AS MATERIALIZED
  (SELECT mc.movie_id
   FROM company_name AS cn
   JOIN movie_companies AS mc ON cn.id = mc.company_id
   WHERE cn.country_code = '[us]'),
     valid_cast_info AS MATERIALIZED
  (SELECT ci.person_id, ci.movie_id, ci.person_role_id
   FROM cast_info AS ci
   JOIN role_type AS rt ON ci.role_id = rt.id
   WHERE rt.role = 'actress'
     AND ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)'))
SELECT MIN(an.name),
       MIN(chn.name),
       MIN(fa.name),
       MIN(t.title)
FROM valid_cast_info vci
JOIN filtered_actresses fa ON vci.person_id = fa.id
JOIN filtered_movies fm ON vci.movie_id = fm.movie_id
JOIN title t ON t.id = fm.movie_id
JOIN aka_name an ON an.person_id = fa.id
JOIN char_name chn ON chn.id = vci.person_role_id;