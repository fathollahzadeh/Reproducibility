
SELECT MIN(t.title) AS american_movie
FROM title AS t
INNER JOIN
  (SELECT DISTINCT movie_id
   FROM movie_info
   WHERE info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German', 'USA', 'American')) AS mi_filtered ON t.id = mi_filtered.movie_id
INNER JOIN
  (SELECT DISTINCT mc.movie_id
   FROM movie_companies AS mc
   JOIN company_type AS ct ON mc.company_type_id = ct.id
   WHERE ct.kind = 'production companies'
     AND mc.note NOT LIKE '%(TV)%'
     AND mc.note LIKE '%(USA)%') AS mc_filtered ON t.id = mc_filtered.movie_id
WHERE t.production_year > 1990;