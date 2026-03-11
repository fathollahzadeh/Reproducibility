WITH filtered_movies AS
  (SELECT DISTINCT mk.movie_id
   FROM keyword AS k
   JOIN movie_keyword AS mk ON k.id = mk.keyword_id
   JOIN movie_companies AS mc ON mk.movie_id = mc.movie_id
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE k.keyword = 'character-name-in-title')
SELECT MIN(n.name) AS member_in_charnamed_movie
FROM name AS n
JOIN cast_info AS ci ON n.id = ci.person_id
JOIN filtered_movies AS fm ON ci.movie_id = fm.movie_id
WHERE n.name LIKE '%B%';