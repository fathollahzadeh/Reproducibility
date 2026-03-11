WITH filtered_companies AS
  (SELECT mc.movie_id,
          cn.name,
          mc.note
   FROM movie_companies AS mc
   JOIN company_name AS cn ON mc.company_id = cn.id
   JOIN company_type AS ct ON mc.company_type_id = ct.id
   WHERE mc.note IS NOT NULL
     AND ct.kind != 'production companies'
     AND cn.country_code != '[pl]'
     AND (cn.name LIKE '20th Century Fox%'
          OR cn.name LIKE 'Twentieth Century Fox%')),
     filtered_keywords AS
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('sequel', 'revenge', 'based-on-novel'))
SELECT MIN(fc.name) AS from_company,
       MIN(fc.note) AS production_note,
       MIN(t.title) AS movie_based_on_book
FROM title AS t
JOIN filtered_companies AS fc ON t.id = fc.movie_id
JOIN filtered_keywords AS fk ON t.id = fk.movie_id
JOIN movie_link AS ml ON t.id = ml.movie_id
JOIN link_type AS lt ON ml.link_type_id = lt.id
WHERE t.production_year > 1950;