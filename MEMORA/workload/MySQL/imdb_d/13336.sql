select min(an1.name) as costume_designer_pseudo,
       min(t.title) as movie_with_costumes
from aka_name as an1,
     cast_info as ci,
     company_name as cn,
     movie_companies as mc,
     name as n1,
     role_type as rt,
     title as t
where an1.person_id = n1.id
  and n1.id = ci.person_id
  and ci.movie_id = t.id
  and t.id = mc.movie_id
  and mc.company_id = cn.id
  and ci.role_id = rt.id
  and an1.person_id = ci.person_id
  and ci.movie_id = mc.movie_id
  and cn.country_code = '[fr]'
and rt.role = 'producer';