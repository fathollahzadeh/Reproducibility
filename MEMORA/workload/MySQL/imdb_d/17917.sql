select min(a1.name) as writer_pseudo_name,
       min(t.title) as movie_title
from aka_name as a1,
     cast_info as ci,
     company_name as cn,
     movie_companies as mc,
     name as n1,
     role_type as rt,
     title as t
where a1.person_id = n1.id
  and n1.id = ci.person_id
  and ci.movie_id = t.id
  and t.id = mc.movie_id
  and mc.company_id = cn.id
  and ci.role_id = rt.id
  and a1.person_id = ci.person_id
  and ci.movie_id = mc.movie_id
  and cn.country_code = '[fr]'
and rt.role = 'actress';