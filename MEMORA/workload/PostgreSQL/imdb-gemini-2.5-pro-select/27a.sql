
SELECT MIN(cn.name) AS producing_company,
       MIN(lt.link) AS link_type,
       MIN(t.title) AS complete_western_sequel
FROM keyword AS k
JOIN movie_keyword AS mk ON k.id = mk.keyword_id
JOIN title AS t ON mk.movie_id = t.id
AND t.production_year BETWEEN 1950 AND 2000
JOIN movie_info AS mi ON t.id = mi.movie_id
AND mi.info IN ('Sweden', 'Germany', 'Swedish', 'German')
JOIN movie_companies AS mc ON t.id = mc.movie_id
AND mc.note IS NULL
JOIN company_type AS ct ON mc.company_type_id = ct.id
AND ct.kind = 'production companies'
JOIN company_name AS cn ON mc.company_id = cn.id
AND cn.country_code != '[pl]'
AND (cn.name LIKE '%Film%'
     OR cn.name LIKE '%Warner%')
JOIN complete_cast AS cc ON t.id = cc.movie_id
JOIN comp_cast_type AS cct1 ON cc.subject_id = cct1.id
AND cct1.kind IN ('cast', 'crew')
JOIN comp_cast_type AS cct2 ON cc.status_id = cct2.id
AND cct2.kind = 'complete'
JOIN movie_link AS ml ON t.id = ml.movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
AND lt.link LIKE '%follow%'
WHERE k.keyword = 'sequel';