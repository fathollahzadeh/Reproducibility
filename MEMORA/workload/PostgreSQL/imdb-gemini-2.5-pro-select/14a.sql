
SELECT MIN(mi_idx.info) AS rating,
       MIN(t.title) AS northern_dark_movie
FROM title AS t
JOIN kind_type AS kt ON t.kind_id = kt.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
WHERE t.production_year > 2010
  AND kt.kind = 'movie'
  AND mi_idx.info < '8.5'
  AND it2.info = 'rating'
  AND EXISTS
    (SELECT 1
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = t.id
       AND k.keyword IN ('murder', 'murder-in-title', 'blood', 'violence'))
  AND EXISTS
    (SELECT 1
     FROM movie_info mi
     JOIN info_type it1 ON mi.info_type_id = it1.id
     WHERE mi.movie_id = t.id
       AND mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German', 'USA', 'American')
       AND it1.info = 'countries');