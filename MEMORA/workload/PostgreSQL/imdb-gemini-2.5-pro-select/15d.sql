
SELECT MIN(at.title) AS aka_title,
       MIN(t.title) AS internet_movie_title
FROM company_name AS cn
JOIN movie_companies AS mc ON cn.id = mc.company_id
JOIN title AS t ON mc.movie_id = t.id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN aka_title AS AT ON t.id = at.movie_id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN keyword AS k ON mk.keyword_id = k.id
WHERE t.production_year > 1990
  AND cn.country_code = '[us]'
  AND it1.info = 'release dates'
  AND mi.note LIKE '%internet%';