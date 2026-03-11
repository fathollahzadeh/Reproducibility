WITH filtered_kt_id AS
  (SELECT id
   FROM kind_type
   WHERE kind = 'movie'),
     filtered_k_ids AS
  (SELECT id
   FROM keyword
   WHERE keyword IN ('murder', 'murder-in-title')),
     filtered_it1_id AS
  (SELECT id
   FROM info_type
   WHERE info = 'countries'),
     filtered_it2_id AS
  (SELECT id
   FROM info_type
   WHERE info = 'rating')
SELECT MIN(mi_idx.info) AS rating,
       MIN(t.title) AS western_dark_production
FROM title AS t
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
WHERE t.kind_id IN
    (SELECT id
     FROM filtered_kt_id)
  AND t.production_year > 2010
  AND (t.title LIKE '%Mord%'
       OR t.title LIKE '%murder%'
       OR t.title LIKE '%Murder%')
  AND mk.keyword_id IN
    (SELECT id
     FROM filtered_k_ids)
  AND mi.info_type_id IN
    (SELECT id
     FROM filtered_it1_id)
  AND mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German', 'USA', 'American')
  AND mi_idx.info_type_id IN
    (SELECT id
     FROM filtered_it2_id)
  AND mi_idx.info > '6.0';