
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS western_violent_movie
FROM title AS t
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
WHERE t.production_year > 2005
  AND mi_idx.info < '8.5'
  AND cn.country_code != '[us]'
  AND it2.info = 'rating'
  AND t.kind_id IN
    (SELECT id
     FROM kind_type
     WHERE kind IN ('movie', 'episode'))
  AND t.id IN
    (SELECT movie_id
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE k.keyword IN ('murder', 'murder-in-title', 'blood', 'violence'))
  AND t.id IN
    (SELECT movie_id
     FROM movie_info mi
     JOIN info_type it1 ON mi.info_type_id = it1.id
     WHERE it1.info = 'countries'
       AND mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Danish', 'Norwegian', 'German', 'USA', 'American'));