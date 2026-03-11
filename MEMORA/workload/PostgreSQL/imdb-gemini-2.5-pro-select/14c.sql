WITH filtered_mk AS
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('murder', 'murder-in-title', 'blood', 'violence')),
     filtered_mi AS
  (SELECT mi.movie_id
   FROM movie_info AS mi
   JOIN info_type AS it1 ON mi.info_type_id = it1.id
   WHERE it1.info = 'countries'
     AND mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Danish', 'Norwegian', 'German', 'USA', 'American')),
     filtered_mi_idx AS
  (SELECT mi_idx.movie_id,
          mi_idx.info
   FROM movie_info_idx AS mi_idx
   JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
   WHERE it2.info = 'rating'
     AND mi_idx.info < '8.5')
SELECT MIN(f_mi_idx.info) AS rating,
       MIN(t.title) AS north_european_dark_production
FROM title AS t
JOIN kind_type AS kt ON t.kind_id = kt.id
JOIN filtered_mk ON t.id = filtered_mk.movie_id
JOIN filtered_mi ON t.id = filtered_mi.movie_id
JOIN filtered_mi_idx AS f_mi_idx ON t.id = f_mi_idx.movie_id
WHERE t.production_year > 2005
  AND kt.kind IN ('movie', 'episode');