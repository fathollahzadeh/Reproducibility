
SELECT MIN(mi.info),
       MIN(miidx.info),
       MIN(t.title)
FROM title AS t
JOIN kind_type AS kt ON kt.id = t.kind_id
JOIN movie_companies AS mc ON mc.movie_id = t.id
JOIN company_type AS ct ON ct.id = mc.company_type_id
JOIN company_name AS cn ON cn.id = mc.company_id
JOIN movie_info_idx AS miidx ON miidx.movie_id = t.id
JOIN info_type AS it ON it.id = miidx.info_type_id
JOIN movie_info AS mi ON mi.movie_id = t.id
JOIN info_type AS it2 ON it2.id = mi.info_type_id
WHERE kt.kind = 'movie'
  AND ct.kind = 'production companies'
  AND cn.country_code = '[de]'
  AND it.info = 'rating'
  AND it2.info = 'release dates';