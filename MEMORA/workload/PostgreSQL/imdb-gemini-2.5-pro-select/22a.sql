
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS western_violent_movie
FROM title AS t,
     movie_companies AS mc,
     company_name AS cn,
     movie_info_idx AS mi_idx,
     info_type AS it2
WHERE t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND t.id = mi_idx.movie_id
  AND mi_idx.info_type_id = it2.id
  AND t.production_year > 2008
  AND mi_idx.info < '7.0'
  AND cn.country_code != '[us]'
  AND it2.info = 'rating'
  AND mc.note NOT LIKE '%(USA)%'
  AND mc.note LIKE '%(200%)%'
  AND t.kind_id IN
    (SELECT id
     FROM kind_type
     WHERE kind IN ('movie', 'episode'))
  AND t.id IN
    (SELECT movie_id
     FROM movie_keyword
     WHERE keyword_id IN
         (SELECT id
          FROM keyword
          WHERE keyword IN ('murder', 'murder-in-title', 'blood', 'violence')))
  AND t.id IN
    (SELECT movie_id
     FROM movie_info
     WHERE info IN ('Germany', 'German', 'USA', 'American')
       AND info_type_id IN
         (SELECT id
          FROM info_type
          WHERE info = 'countries'));