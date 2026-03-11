
SELECT MIN(chn.name) AS character_name,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS complete_hero_movie
FROM title AS t
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN char_name AS chn ON ci.person_role_id = chn.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
WHERE t.production_year > 2000
  AND (chn.name LIKE '%man%'
       OR chn.name LIKE '%Man%')
  AND t.kind_id IN
    (SELECT id
     FROM kind_type
     WHERE kind = 'movie')
  AND mi_idx.info_type_id IN
    (SELECT id
     FROM info_type
     WHERE info = 'rating')
  AND t.id IN
    (SELECT movie_id
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE k.keyword IN ('superhero', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence', 'magnet', 'web', 'claw', 'laser'))
  AND t.id IN
    (SELECT movie_id
     FROM complete_cast cc
     JOIN comp_cast_type cct1 ON cc.subject_id = cct1.id
     JOIN comp_cast_type cct2 ON cc.status_id = cct2.id
     WHERE cct1.kind = 'cast'
       AND cct2.kind LIKE '%complete%');