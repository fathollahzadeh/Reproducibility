WITH filtered_titles AS
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN kind_type AS kt ON t.kind_id = kt.id
   WHERE kt.kind = 'movie'
     AND t.title != ''
     AND (t.title LIKE 'Champion%'
          OR t.title LIKE 'Loser%'))
SELECT MIN(cn.name) AS producing_company,
       MIN(miidx.info) AS rating,
       MIN(ft.title) AS movie_about_winning
FROM filtered_titles AS ft
JOIN movie_companies AS mc ON ft.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN movie_info_idx AS miidx ON ft.id = miidx.movie_id
WHERE cn.country_code = '[us]'
  AND EXISTS
    (SELECT 1
     FROM company_type AS ct
     WHERE ct.id = mc.company_type_id
       AND ct.kind = 'production companies')
  AND EXISTS
    (SELECT 1
     FROM info_type AS it
     WHERE it.id = miidx.info_type_id
       AND it.info = 'rating')
  AND EXISTS
    (SELECT 1
     FROM movie_info AS mi
     JOIN info_type AS it2 ON mi.info_type_id = it2.id
     WHERE mi.movie_id = ft.id
       AND it2.info = 'release dates');