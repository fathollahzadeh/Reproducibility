WITH movie_details AS
  (SELECT t.id,
          t.title
   FROM title AS t
   JOIN movie_companies AS mc ON t.id = mc.movie_id
   JOIN company_name AS cn ON mc.company_id = cn.id
   WHERE t.production_year > 2010
     AND cn.country_code = '[ru]'),
     cast_details AS
  (SELECT ci.movie_id,
          chn.name
   FROM cast_info AS ci
   JOIN char_name AS chn ON ci.person_role_id = chn.id
   JOIN role_type AS rt ON ci.role_id = rt.id
   WHERE ci.note LIKE '%(producer)%'
     AND rt.role = 'actor')
SELECT MIN(cd.name) AS CHARACTER,
       MIN(md.title) AS russian_mov_with_actor_producer
FROM movie_details AS md
JOIN cast_details AS cd ON md.id = cd.movie_id;