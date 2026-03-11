
SELECT MIN(kt.kind) AS movie_kind,
       MIN(t.title) AS complete_us_internet_movie
FROM title AS t
JOIN kind_type AS kt ON kt.id = t.kind_id
WHERE t.production_year > 2000
  AND kt.kind IN ('movie')
  AND t.id IN
    (SELECT mi.movie_id
     FROM movie_info AS mi
     JOIN info_type AS it1 ON it1.id = mi.info_type_id
     WHERE it1.info = 'release dates'
       AND mi.note LIKE '%internet%'
       AND (mi.info LIKE 'USA:% 199%'
            OR mi.info LIKE 'USA:% 200%'))
  AND t.id IN
    (SELECT movie_id
     FROM movie_keyword)
  AND t.id IN
    (SELECT mc.movie_id
     FROM movie_companies AS mc
     JOIN company_name AS cn ON cn.id = mc.company_id
     WHERE cn.country_code = '[us]')
  AND t.id IN
    (SELECT cc.movie_id
     FROM complete_cast AS cc
     JOIN comp_cast_type AS cct1 ON cct1.id = cc.status_id
     WHERE cct1.kind = 'complete+verified');