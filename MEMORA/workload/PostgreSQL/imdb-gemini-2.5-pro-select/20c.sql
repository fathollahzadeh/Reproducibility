WITH relevant_movies AS
  (SELECT DISTINCT t.id,
                   t.title
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   JOIN movie_keyword AS mk ON t.id = mk.movie_id
   JOIN keyword AS k ON mk.keyword_id = k.id
   JOIN complete_cast AS cc ON t.id = cc.movie_id
   JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
   JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
   WHERE t.production_year > 2000
     AND kt.kind = 'movie'
     AND k.keyword IN ('superhero', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence', 'magnet', 'web', 'claw', 'laser')
     AND cct1.kind = 'cast'
     AND cct2.kind LIKE '%complete%')
SELECT MIN(n.name) AS cast_member,
       MIN(rm.title) AS complete_dynamic_hero_movie
FROM cast_info AS ci
JOIN name AS n ON ci.person_id = n.id
JOIN char_name AS chn ON ci.person_role_id = chn.id
JOIN relevant_movies AS rm ON ci.movie_id = rm.id
WHERE chn.name IS NOT NULL
  AND (chn.name LIKE '%man%'
       OR chn.name LIKE '%Man%');