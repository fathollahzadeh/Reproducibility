SELECT MIN(mi.info) AS release_date,
       MIN(t.title) AS modern_american_internet_movie
FROM title AS t
JOIN aka_title AS AT ON t.id = at.movie_id
JOIN movie_info AS mi ON t.id = mi.movie_id
JOIN movie_keyword AS mk ON t.id = mk.movie_id
JOIN movie_companies AS mc ON t.id = mc.movie_id
JOIN keyword AS k ON mk.keyword_id = k.id
JOIN info_type AS it1 ON mi.info_type_id = it1.id
JOIN company_name AS cn ON mc.company_id = cn.id
JOIN company_type AS ct ON mc.company_type_id = ct.id
WHERE cn.country_code = '[us]'
  AND it1.info = 'release dates'
  AND mi.note LIKE '%internet%'
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'USA:% 199%'
       OR mi.info LIKE 'USA:% 200%')
  AND t.production_year > 1990;