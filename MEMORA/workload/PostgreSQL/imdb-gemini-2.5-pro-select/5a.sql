
SELECT MIN(t.title) AS typical_european_movie
FROM title AS t
WHERE t.production_year > 2005
  AND t.id IN
    (SELECT mc.movie_id
     FROM movie_companies AS mc
     JOIN company_type AS ct ON mc.company_type_id = ct.id
     WHERE ct.kind = 'production companies'
       AND mc.note LIKE '%(France)%'
       AND mc.note LIKE '%(theatrical)%')
  AND t.id IN
    (SELECT mi.movie_id
     FROM movie_info AS mi
     JOIN info_type AS it ON mi.info_type_id = it.id
     WHERE mi.info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German'));