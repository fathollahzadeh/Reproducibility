WITH filtered_keywords AS
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('nerd', 'loner', 'alienation', 'dignity')),
     filtered_info AS
  (SELECT mi.movie_id
   FROM movie_info AS mi
   JOIN info_type AS it1 ON mi.info_type_id = it1.id
   WHERE it1.info = 'release dates'
     AND mi.note LIKE '%internet%'
     AND mi.info LIKE 'USA:% 200%'),
     filtered_companies AS
  (SELECT mc.movie_id
   FROM movie_companies AS mc
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE cn.country_code = '[us]'),
     filtered_cast AS
  (SELECT cc.movie_id
   FROM complete_cast AS cc
   JOIN comp_cast_type AS cct1 ON cc.status_id = cct1.id
   WHERE cct1.kind = 'complete+verified')
SELECT MIN(kt.kind),
       MIN(t.title)
FROM title AS t
JOIN kind_type AS kt ON t.kind_id = kt.id
JOIN filtered_keywords AS fk ON t.id = fk.movie_id
JOIN filtered_info AS fi ON t.id = fi.movie_id
JOIN filtered_companies AS fc ON t.id = fc.movie_id
JOIN filtered_cast AS fcast ON t.id = fcast.movie_id
WHERE t.production_year > 2000
  AND kt.kind IN ('movie');