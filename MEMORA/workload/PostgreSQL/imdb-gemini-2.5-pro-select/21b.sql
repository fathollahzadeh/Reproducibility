
SELECT MIN(cn.name) AS company_name,
       MIN(lt.link) AS link_type,
       MIN(t.title) AS german_follow_up
FROM title AS t
JOIN movie_companies AS mc ON t.id = mc.movie_id
AND mc.note IS NULL
JOIN company_name AS cn ON mc.company_id = cn.id
AND cn.country_code != '[pl]'
AND (cn.name LIKE '%Film%'
     OR cn.name LIKE '%Warner%')
JOIN movie_link AS ml ON t.id = ml.movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
AND lt.link LIKE '%follow%'
WHERE t.production_year BETWEEN 2000 AND 2010
  AND EXISTS
    (SELECT 1
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = t.id
       AND k.keyword = 'sequel')
  AND EXISTS
    (SELECT 1
     FROM movie_info mi
     WHERE mi.movie_id = t.id
       AND mi.info IN ('Germany', 'German'))
  AND EXISTS
    (SELECT 1
     FROM movie_companies mc2
     JOIN company_type ct ON mc2.company_type_id = ct.id
     WHERE mc2.movie_id = t.id
       AND ct.kind = 'production companies');