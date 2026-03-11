
SELECT MIN(cn.name) AS from_company,
       MIN(mc.note) AS production_note,
       MIN(t.title) AS movie_based_on_book
FROM movie_companies AS mc
JOIN title AS t ON mc.movie_id = t.id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
WHERE t.production_year > 1950
  AND mc.note IS NOT NULL
  AND cn.country_code != '[pl]'
  AND ct.kind != 'production companies'
  AND mc.movie_id IN
    (SELECT movie_id
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE k.keyword IN ('sequel', 'revenge', 'based-on-novel'))
  AND mc.movie_id IN
    (SELECT movie_id
     FROM movie_link);