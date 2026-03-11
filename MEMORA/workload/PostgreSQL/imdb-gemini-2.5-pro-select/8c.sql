WITH company_movies AS
  (SELECT DISTINCT mc.movie_id
   FROM company_name cn
   JOIN movie_companies mc ON cn.id = mc.company_id
   WHERE cn.country_code = '[us]'),
     person_roles AS
  (SELECT ci.person_id,
          ci.movie_id
   FROM role_type rt
   JOIN cast_info ci ON rt.id = ci.role_id
   WHERE rt.role = 'writer')
SELECT MIN(a1.name) AS writer_pseudo_name,
       MIN(t.title) AS movie_title
FROM person_roles pr
JOIN company_movies cm ON pr.movie_id = cm.movie_id
JOIN title t ON pr.movie_id = t.id
JOIN aka_name a1 ON pr.person_id = a1.person_id;