
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS complete_euro_dark_movie
FROM title AS t,
     movie_info_idx AS mi_idx,
     movie_companies AS mc,
     company_name AS cn
WHERE t.id = mi_idx.movie_id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND t.production_year > 2000
  AND mi_idx.info < '8.5'
  AND cn.country_code != '[us]'
  AND mc.note NOT LIKE '%(USA)%'
  AND mc.note LIKE '%(200%)%'
  AND t.kind_id IN
    (SELECT id
     FROM kind_type
     WHERE kind IN ('movie', 'episode'))
  AND mi_idx.info_type_id IN
    (SELECT id
     FROM info_type
     WHERE info = 'rating')
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
     WHERE info_type_id IN
         (SELECT id
          FROM info_type
          WHERE info = 'countries')
       AND info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Danish', 'Norwegian', 'German', 'USA', 'American'))
  AND t.id IN
    (SELECT movie_id
     FROM complete_cast
     WHERE subject_id IN
         (SELECT id
          FROM comp_cast_type
          WHERE kind = 'crew')
       AND status_id IN
         (SELECT id
          FROM comp_cast_type
          WHERE kind != 'complete+verified'));