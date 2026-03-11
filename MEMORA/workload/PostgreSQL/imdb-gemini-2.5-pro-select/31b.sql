WITH filtered_titles AS
  (SELECT id
   FROM title
   WHERE production_year > 2000
     AND (title LIKE 'Saw%'
          OR title LIKE '%Freddy%'
          OR title LIKE '%Jason%')),
     company_movies AS
  (SELECT mc.movie_id
   FROM movie_companies AS mc
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE cn.name LIKE 'Lionsgate%'
     AND mc.note LIKE '%(Blu-ray)%'),
     keyword_movies AS
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital'))
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS writer,
       MIN(t.title) AS violent_liongate_movie
FROM title AS t
JOIN filtered_titles ft ON t.id = ft.id
JOIN company_movies cm ON t.id = cm.movie_id
JOIN keyword_movies km ON t.id = km.movie_id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
AND it1.info = 'genres'
JOIN movie_info_idx AS mi_idx ON t.id = mi_idx.movie_id
JOIN info_type AS it2 ON mi_idx.info_type_id = it2.id
AND it2.info = 'votes'
JOIN cast_info AS ci ON t.id = ci.movie_id
JOIN name AS n ON ci.person_id = n.id
WHERE mi.info IN ('Horror', 'Thriller')
  AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)')
  AND n.gender = 'm';