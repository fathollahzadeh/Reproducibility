WITH filtered_titles AS
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE t.production_year > 2000
     AND kt.kind = 'movie'),
     movie_keywords AS
  (SELECT DISTINCT movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('superhero', 'sequel', 'second-part', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence')),
     movie_cast AS
  (SELECT DISTINCT ci.movie_id
   FROM cast_info AS ci
   JOIN name AS n ON ci.person_id = n.id
   JOIN char_name AS chn ON ci.person_role_id = chn.id
   WHERE n.name LIKE '%Downey%Robert%'
     AND chn.name NOT LIKE '%Sherlock%'
     AND (chn.name LIKE '%Tony%Stark%'
          OR chn.name LIKE '%Iron%Man%')),
     movie_complete_cast AS
  (SELECT DISTINCT cc.movie_id
   FROM complete_cast AS cc
   JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
   JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
   WHERE cct1.kind = 'cast'
     AND cct2.kind LIKE '%complete%')
SELECT MIN(ft.title) AS complete_downey_ironman_movie
FROM filtered_titles AS ft
JOIN movie_keywords AS mk ON ft.id = mk.movie_id
JOIN movie_cast AS mc ON ft.id = mc.movie_id
JOIN movie_complete_cast AS mcc ON ft.id = mcc.movie_id;