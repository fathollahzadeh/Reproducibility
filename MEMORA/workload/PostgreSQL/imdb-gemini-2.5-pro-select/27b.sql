
SELECT MIN(cn.name),
       MIN(lt.link),
       MIN(t.title)
FROM keyword AS k
JOIN movie_keyword AS mk ON k.id = mk.keyword_id
JOIN title AS t ON mk.movie_id = t.id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN movie_link AS ml ON t.id = ml.movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
JOIN complete_cast AS cc ON t.id = cc.movie_id
JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
JOIN movie_info AS mi ON t.id = mi.movie_id
WHERE t.production_year = 1998
  AND k.keyword = 'sequel'
  AND mi.info IN ('Sweden', 'Germany', 'Swedish', 'German')
  AND mc.note IS NULL
  AND cn.country_code != '[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND ct.kind = 'production companies'
  AND lt.link LIKE '%follow%'
  AND cct1.kind IN ('cast', 'crew')
  AND cct2.kind = 'complete';