
SELECT MIN(cn.name),
       MIN(lt.link),
       MIN(t.title)
FROM title AS t
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN movie_link AS ml ON t.id = ml.movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
JOIN movie_info AS mi ON t.id = mi.movie_id
WHERE t.production_year BETWEEN 1950 AND 2010
  AND k.keyword = 'sequel'
  AND ct.kind = 'production companies'
  AND mc.note IS NULL
  AND cn.country_code != '[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND lt.link LIKE '%follow%'
  AND mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German', 'English');