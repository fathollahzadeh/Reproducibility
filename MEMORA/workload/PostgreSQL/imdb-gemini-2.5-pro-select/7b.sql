
SELECT MIN(n.name) AS of_person,
       MIN(t.title) AS biography_movie
FROM
  (SELECT id,
          name
   FROM name
   WHERE name_pcode_cf LIKE 'D%'
     AND gender = 'm') AS n
JOIN
  (SELECT person_id
   FROM aka_name
   WHERE name LIKE '%a%') AS an ON n.id = an.person_id
JOIN
  (SELECT pi.person_id
   FROM person_info AS pi
   JOIN info_type AS it ON pi.info_type_id = it.id
   WHERE pi.note = 'Volker Boehm'
     AND it.info = 'mini biography') AS pi ON n.id = pi.person_id
JOIN cast_info AS ci ON n.id = ci.person_id
JOIN
  (SELECT id,
          title
   FROM title
   WHERE production_year BETWEEN 1980 AND 1984) AS t ON ci.movie_id = t.id
JOIN
  (SELECT ml.linked_movie_id
   FROM movie_link AS ml
   JOIN link_type AS lt ON ml.link_type_id = lt.id
   WHERE lt.link = 'features') AS ml ON t.id = ml.linked_movie_id;