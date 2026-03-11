WITH qualifying_movie_ids AS
  (SELECT mi.movie_id
   FROM movie_info AS mi
   JOIN movie_companies AS mc ON mi.movie_id = mc.movie_id
   JOIN company_type AS ct ON mc.company_type_id = ct.id
   WHERE mi.info IN ('USA', 'America')
     AND ct.kind = 'production companies'
     AND mc.note LIKE '%(1994)%'
     AND mc.note LIKE '%(USA)%'
     AND mc.note LIKE '%(VHS)%'
   GROUP BY mi.movie_id)
SELECT MIN(t.title)
FROM title AS t
JOIN qualifying_movie_ids AS q ON t.id = q.movie_id
WHERE t.production_year > 2010;