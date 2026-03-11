
SELECT MIN(cn.name),
       MIN(miidx.info),
       MIN(t.title)
FROM title AS t
JOIN kind_type AS kt ON t.kind_id = kt.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN movie_info_idx AS miidx ON t.id = miidx.movie_id
JOIN info_type AS it ON miidx.info_type_id = it.id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it2 ON mi.info_type_id = it2.id
WHERE kt.kind = 'movie'
  AND cn.country_code = '[us]'
  AND ct.kind = 'production companies'
  AND it.info = 'rating'
  AND it2.info = 'release dates';