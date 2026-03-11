
SELECT MIN(cn.name),
       MIN(mi_idx.info),
       MIN(t.title)
FROM title AS t
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
WHERE cn.country_code != '[us]'
  AND mc.note NOT LIKE '%(USA)%'
  AND mc.note LIKE '%(200%)%'
  AND mi_idx.info > '6.5'
  AND mi_idx.info_type_id IN
    (SELECT id
     FROM info_type
     WHERE info = 'rating')
  AND t.id IN
    (SELECT t.id
     FROM title t
     JOIN kind_type kt ON t.kind_id = kt.id
     WHERE t.production_year > 2005
       AND kt.kind IN ('movie', 'episode') INTERSECT
       SELECT mk.movie_id
       FROM movie_keyword mk
       JOIN keyword k ON mk.keyword_id = k.id WHERE k.keyword IN ('murder', 'murder-in-title', 'blood', 'violence') INTERSECT
       SELECT mi.movie_id
       FROM movie_info mi
       JOIN info_type it1 ON mi.info_type_id = it1.id WHERE it1.info = 'countries'
       AND mi.info IN ('Sweden', 'Germany', 'Swedish', 'German') INTERSECT
       SELECT cc.movie_id
       FROM complete_cast cc
       JOIN comp_cast_type cct1 ON cct1.id = cc.subject_id
       JOIN comp_cast_type cct2 ON cct2.id = cc.status_id WHERE cct1.kind = 'crew'
       AND cct2.kind != 'complete+verified');