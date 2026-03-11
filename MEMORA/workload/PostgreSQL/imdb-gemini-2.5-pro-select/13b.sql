
SELECT MIN(cn.name) AS producing_company,
       MIN(miidx.info) AS rating,
       MIN(t.title) AS movie_about_winning
FROM title AS t
INNER JOIN kind_type AS kt ON t.kind_id = kt.id
AND kt.kind = 'movie'
INNER JOIN movie_companies AS mc ON t.id = mc.movie_id
INNER JOIN company_name AS cn ON mc.company_id = cn.id
AND cn.country_code = '[us]'
INNER JOIN company_type AS ct ON mc.company_type_id = ct.id
AND ct.kind = 'production companies'
INNER JOIN movie_info_idx AS miidx ON t.id = miidx.movie_id
INNER JOIN info_type AS it ON miidx.info_type_id = it.id
AND it.info = 'rating'
INNER JOIN movie_info AS mi ON t.id = mi.movie_id
INNER JOIN info_type AS it2 ON mi.info_type_id = it2.id
AND it2.info = 'release dates'
WHERE t.title != ''
  AND (t.title LIKE '%Champion%'
       OR t.title LIKE '%Loser%');