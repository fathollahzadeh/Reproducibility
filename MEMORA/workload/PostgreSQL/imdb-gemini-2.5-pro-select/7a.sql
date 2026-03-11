
SELECT MIN(n.name) AS of_person,
       MIN(t.title) AS biography_movie
FROM name AS n
JOIN person_info AS pi ON n.id = pi.person_id
JOIN info_type AS it ON pi.info_type_id = it.id
JOIN aka_name AS an ON n.id = an.person_id
JOIN cast_info AS ci ON n.id = ci.person_id
JOIN title AS t ON ci.movie_id = t.id
JOIN movie_link AS ml ON t.id = ml.linked_movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
WHERE it.info = 'mini biography'
  AND lt.link = 'features'
  AND an.name LIKE '%a%'
  AND pi.note = 'Volker Boehm'
  AND t.production_year BETWEEN 1980 AND 1995
  AND n.name_pcode_cf BETWEEN 'A' AND 'F'
  AND (n.gender = 'm'
       OR (n.gender = 'f'
           AND n.name LIKE 'B%'));