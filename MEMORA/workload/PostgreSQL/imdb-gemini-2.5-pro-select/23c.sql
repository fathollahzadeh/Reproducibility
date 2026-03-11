
SELECT MIN(kt.kind),
       MIN(t.title)
FROM movie_info AS mi
JOIN info_type AS it1 ON it1.id = mi.info_type_id
AND it1.info = 'release dates'
JOIN title AS t ON t.id = mi.movie_id
AND t.production_year > 1990
JOIN kind_type AS kt ON kt.id = t.kind_id
AND kt.kind IN ('movie', 'tv movie', 'video movie', 'video game')
WHERE mi.note LIKE '%internet%'
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'USA:% 199%'
       OR mi.info LIKE 'USA:% 200%')
  AND EXISTS
    (SELECT 1
     FROM movie_keyword AS mk
     WHERE mk.movie_id = t.id)
  AND EXISTS
    (SELECT 1
     FROM movie_companies mc
     JOIN company_name cn ON cn.id = mc.company_id
     AND cn.country_code = '[us]'
     WHERE mc.movie_id = t.id)
  AND EXISTS
    (SELECT 1
     FROM complete_cast cc
     JOIN comp_cast_type cct1 ON cct1.id = cc.status_id
     AND cct1.kind = 'complete+verified'
     WHERE cc.movie_id = t.id);