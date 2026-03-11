WITH movie_subset AS
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE t.production_year > 2000
     AND kt.kind = 'movie')
SELECT MIN(chn.name),
       MIN(mi_idx.info),
       MIN(n.name),
       MIN(ms.title)
FROM movie_subset AS ms
JOIN movie_keyword AS mk ON ms.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN movie_info_idx AS mi_idx ON ms.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
JOIN cast_info AS ci ON ms.id = ci.movie_id
JOIN name AS n ON ci.person_id = n.id
JOIN char_name AS chn ON ci.person_role_id = chn.id
JOIN complete_cast AS cc ON ms.id = cc.movie_id
JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
WHERE k.keyword IN ('superhero', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence', 'magnet', 'web', 'claw', 'laser')
  AND it2.info = 'rating'
  AND mi_idx.info > '7.0'
  AND (chn.name LIKE '%man%'
       OR chn.name LIKE '%Man%')
  AND cct1.kind = 'cast'
  AND cct2.kind LIKE '%complete%';