WITH title_filtered AS
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE t.production_year > 2005
     AND kt.kind IN ('movie', 'episode')),
     keyword_filtered AS
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('murder', 'murder-in-title', 'blood', 'violence')),
     info_filtered AS
  (SELECT mi.movie_id
   FROM movie_info AS mi
   JOIN info_type AS it1 ON mi.info_type_id = it1.id
   WHERE mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Danish', 'Norwegian', 'German', 'USA', 'American')
     AND it1.info = 'countries')
SELECT MIN(cn.name),
       MIN(mi_idx.info),
       MIN(tf.title)
FROM title_filtered AS tf
JOIN keyword_filtered kf ON tf.id = kf.movie_id
JOIN info_filtered inf ON tf.id = inf.movie_id
JOIN movie_info_idx AS mi_idx ON tf.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
JOIN movie_companies AS mc ON tf.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN complete_cast AS cc ON tf.id = cc.movie_id
JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
WHERE mi_idx.info < '8.5'
  AND it2.info = 'rating'
  AND mc.note NOT LIKE '%(USA)%'
  AND mc.note LIKE '%(200%)%'
  AND cn.country_code != '[us]'
  AND cct1.kind = 'cast'
  AND cct2.kind = 'complete';