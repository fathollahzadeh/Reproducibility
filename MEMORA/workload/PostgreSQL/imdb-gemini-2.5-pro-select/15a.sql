
SELECT MIN(mi.info) AS release_date,
       MIN(t.title) AS internet_movie
FROM title AS t
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN movie_companies AS mc ON t.id = mc.movie_id
WHERE t.production_year > 2000
  AND mi.note LIKE '%internet%'
  AND mi.info LIKE 'USA:% 200%'
  AND mc.note LIKE '%(worldwide)%'
  AND mc.note LIKE '%(200%)%'
  AND EXISTS
    (SELECT 1
     FROM info_type AS it1
     WHERE it1.id = mi.info_type_id
       AND it1.info = 'release dates')
  AND EXISTS
    (SELECT 1
     FROM company_name AS cn
     WHERE cn.id = mc.company_id
       AND cn.country_code = '[us]')
  AND EXISTS
    (SELECT 1
     FROM company_type AS ct
     WHERE ct.id = mc.company_type_id)
  AND EXISTS
    (SELECT 1
     FROM movie_keyword AS mk
     WHERE mk.movie_id = t.id)
  AND EXISTS
    (SELECT 1
     FROM aka_title AS AT
     WHERE at.movie_id = t.id);