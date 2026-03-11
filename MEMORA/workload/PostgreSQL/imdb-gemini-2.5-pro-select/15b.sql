
SELECT MIN(mi.info) AS release_date,
       MIN(t.title) AS youtube_movie
FROM title AS t
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN aka_title AS AT ON t.id = at.movie_id
WHERE cn.country_code = '[us]'
  AND cn.name = 'YouTube'
  AND it1.info = 'release dates'
  AND mc.note LIKE '%(worldwide)%'
  AND mc.note LIKE '%(200%)%'
  AND mi.note LIKE '%internet%'
  AND mi.info LIKE 'USA:% 200%'
  AND t.production_year BETWEEN 2005 AND 2010;