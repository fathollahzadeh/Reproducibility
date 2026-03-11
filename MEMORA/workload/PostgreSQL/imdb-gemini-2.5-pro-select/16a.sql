WITH filtered_movies AS
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN movie_keyword AS mk ON t.id = mk.movie_id
   JOIN keyword AS k ON mk.keyword_id = k.id
   JOIN movie_companies AS mc ON t.id = mc.movie_id
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE t.episode_nr >= 50
     AND t.episode_nr < 100
     AND k.keyword = 'character-name-in-title'
     AND cn.country_code = '[us]')
SELECT MIN(an.name),
       MIN(fm.title)
FROM filtered_movies AS fm
JOIN cast_info AS ci ON fm.id = ci.movie_id
JOIN aka_name AS an ON ci.person_id = an.person_id;