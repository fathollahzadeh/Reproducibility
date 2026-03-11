WITH filtered_keywords AS
  (SELECT mk.movie_id
   FROM keyword AS k
   JOIN movie_keyword AS mk ON k.id = mk.keyword_id
   WHERE k.keyword = 'character-name-in-title'),
     filtered_companies AS
  (SELECT mc.movie_id
   FROM company_name AS cn
   JOIN movie_companies AS mc ON cn.id = mc.company_id
   WHERE cn.country_code = '[us]'),
     filtered_names AS
  (SELECT ci.movie_id,
          n.name
   FROM name AS n
   JOIN cast_info AS ci ON n.id = ci.person_id
   WHERE n.name LIKE 'B%')
SELECT MIN(fn.name) AS member_in_charnamed_american_movie,
       MIN(fn.name) AS a1
FROM filtered_names AS fn
JOIN filtered_keywords AS fk ON fn.movie_id = fk.movie_id
JOIN filtered_companies AS fc ON fn.movie_id = fc.movie_id;