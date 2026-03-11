
SELECT MIN(cn.name),
       MIN(mi_idx.info),
       MIN(t.title)
FROM title AS t
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
WHERE t.production_year > 2009
  AND cn.country_code != '[us]'
  AND mc.note NOT LIKE '%(USA)%'
  AND mc.note LIKE '%(200%)%'
  AND mi_idx.info < '7.0'
  AND t.kind_id IN
    (SELECT id
     FROM kind_type
     WHERE kind IN ('movie', 'episode'))
  AND mi_idx.info_type_id =
    (SELECT id
     FROM info_type
     WHERE info = 'rating')
  AND EXISTS
    (SELECT 1
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = t.id
       AND k.keyword IN ('murder', 'murder-in-title', 'blood', 'violence'))
  AND EXISTS
    (SELECT 1
     FROM movie_info mi
     WHERE mi.movie_id = t.id
       AND mi.info IN ('Germany', 'German', 'USA', 'American')
       AND mi.info_type_id =
         (SELECT id
          FROM info_type
          WHERE info = 'countries'));