
SELECT MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress_name,
       MIN(filtered_movies.title) AS kung_fu_panda
FROM
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN movie_companies AS mc ON t.id = mc.movie_id
   JOIN company_name AS cn ON mc.company_id = cn.id
   JOIN movie_keyword AS mk ON t.id = mk.movie_id
   JOIN keyword AS k ON mk.keyword_id = k.id
   JOIN movie_info AS mi ON t.id = mi.movie_id
   JOIN info_type AS it ON mi.info_type_id = it.id
   WHERE t.production_year > 2010
     AND t.title LIKE 'Kung Fu Panda%'
     AND cn.country_code = '[us]'
     AND cn.name = 'DreamWorks Animation'
     AND k.keyword IN ('hero', 'martial-arts', 'hand-to-hand-combat', 'computer-animated-movie')
     AND it.info = 'release dates'
     AND mi.info IS NOT NULL
     AND (mi.info LIKE 'Japan:%201%'
          OR mi.info LIKE 'USA:%201%')) AS filtered_movies
JOIN cast_info AS ci ON filtered_movies.id = ci.movie_id
JOIN name AS n ON ci.person_id = n.id
JOIN char_name AS chn ON ci.person_role_id = chn.id
JOIN role_type AS rt ON ci.role_id = rt.id
JOIN aka_name AS an ON n.id = an.person_id
WHERE n.gender = 'f'
  AND n.name LIKE '%An%'
  AND rt.role = 'actress'
  AND ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)');