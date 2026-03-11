WITH link_ids AS
  (SELECT id
   FROM link_type
   WHERE LINK IN ('references', 'referenced in', 'features', 'featured in'))
SELECT MIN(n.name) AS cast_member_name,
       MIN(pi.info) AS cast_member_info
FROM name AS n
JOIN person_info AS pi ON n.id = pi.person_id
JOIN info_type AS it ON it.id = pi.info_type_id
WHERE n.name_pcode_cf BETWEEN 'A' AND 'F'
  AND (n.gender = 'm'
       OR (n.gender = 'f'
           AND n.name LIKE 'A%'))
  AND pi.note IS NOT NULL
  AND it.info = 'mini biography'
  AND EXISTS
    (SELECT 1
     FROM aka_name an
     WHERE an.person_id = n.id
       AND (an.name LIKE '%a%'
            OR an.name LIKE 'A%'))
  AND EXISTS
    (SELECT 1
     FROM cast_info ci
     JOIN title t ON t.id = ci.movie_id
     AND t.production_year BETWEEN 1980 AND 2010
     JOIN movie_link ml ON ml.linked_movie_id = t.id
     JOIN link_ids li ON li.id = ml.link_type_id
     WHERE ci.person_id = n.id);