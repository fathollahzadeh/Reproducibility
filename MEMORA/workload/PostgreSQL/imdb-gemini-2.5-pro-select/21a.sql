
SELECT MIN(cn.name),
       MIN(lt.link),
       MIN(t.title)
FROM keyword AS k
JOIN movie_keyword AS mk ON k.id = mk.keyword_id
JOIN title AS t ON mk.movie_id = t.id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN movie_link AS ml ON t.id = ml.movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
WHERE k.keyword = 'sequel'
  AND t.production_year BETWEEN 1950 AND 2000
  AND mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German')
  AND mc.note IS NULL
  AND ct.kind = 'production companies'
  AND cn.country_code != '[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND lt.link LIKE '%follow%';