
SELECT MIN(chn.name) AS CHARACTER,
       MIN(t.title) AS movie_with_american_producer
FROM
  (SELECT id,
          title
   FROM title
   WHERE production_year > 1990) AS t
JOIN
  (SELECT mc.movie_id,
          mc.company_type_id
   FROM movie_companies AS mc
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE cn.country_code = '[us]') AS mc_filtered ON t.id = mc_filtered.movie_id
JOIN
  (SELECT movie_id,
          person_role_id,
          role_id
   FROM cast_info
   WHERE note LIKE '%(producer)%') AS ci ON t.id = ci.movie_id
JOIN char_name AS chn ON ci.person_role_id = chn.id
JOIN role_type AS rt ON ci.role_id = rt.id
JOIN company_type AS ct ON mc_filtered.company_type_id = ct.id;