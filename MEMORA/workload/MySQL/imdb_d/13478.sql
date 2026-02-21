select min(chn.name) AS character_,
       min(t.title) as movie_with_american_producer
from char_name as chn,
     cast_info as ci,
     company_name as cn,
     company_type as ct,
     movie_companies as mc,
     role_type as rt,
     title as t
where t.id = mc.movie_id
  and t.id = ci.movie_id
  and ci.movie_id = mc.movie_id
  and chn.id = ci.person_role_id
  and rt.id = ci.role_id
  and cn.id = mc.company_id
  and ct.id = mc.company_type_id
  and ci.note like '%marcy%'
and cn.country_code = '[gb]'
and t.production_year > 2009;