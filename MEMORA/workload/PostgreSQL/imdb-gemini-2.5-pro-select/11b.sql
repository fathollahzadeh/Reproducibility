
SELECT MIN(cn.name),
       MIN(lt.link),
       MIN(t.title)
FROM title AS t
JOIN movie_companies AS mc ON t.id = mc.movie_id
AND mc.note IS NULL
JOIN company_name AS cn ON mc.company_id = cn.id
AND cn.country_code != '[pl]'
AND (cn.name LIKE '%Film%'
     OR cn.name LIKE '%Warner%')
JOIN company_type AS ct ON mc.company_type_id = ct.id
AND ct.kind = 'production companies'
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
AND k.keyword = 'sequel'
JOIN movie_link AS ml ON t.id = ml.movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
AND lt.link LIKE '%follows%'
WHERE t.production_year = 1998
  AND t.title LIKE '%Money%';