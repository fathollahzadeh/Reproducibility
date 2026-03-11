WITH filtered_kt AS
  (SELECT id
   FROM kind_type
   WHERE kind = 'movie'),
     filtered_k AS
  (SELECT id
   FROM keyword
   WHERE keyword IN ('superhero', 'marvel-comics', 'based-on-comic', 'fight')),
     filtered_cct1 AS
  (SELECT id
   FROM comp_cast_type
   WHERE kind = 'cast'),
     filtered_cct2 AS
  (SELECT id
   FROM comp_cast_type
   WHERE kind LIKE '%complete%'),
     filtered_it2 AS
  (SELECT id
   FROM info_type
   WHERE info = 'rating')
SELECT MIN(chn.name),
       MIN(mi_idx.info),
       MIN(t.title)
FROM title AS t
JOIN filtered_kt ON t.kind_id = filtered_kt.id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN filtered_k ON mk.keyword_id = filtered_k.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN filtered_it2 ON mi_idx.info_type_id = filtered_it2.id
JOIN complete_cast AS cc ON t.id = cc.movie_id
JOIN filtered_cct1 ON cc.subject_id = filtered_cct1.id
JOIN filtered_cct2 ON cc.status_id = filtered_cct2.id
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN char_name AS chn ON ci.person_role_id = chn.id
WHERE t.production_year > 2005
  AND mi_idx.info > '8.0'
  AND (chn.name LIKE '%man%'
       OR chn.name LIKE '%Man%');