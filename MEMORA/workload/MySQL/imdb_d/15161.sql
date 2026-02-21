select min(an.name) as acress_pseudonym,
       min(t.title) as japanese_anime_movie
from aka_name as an,
     cast_info as ci,
     company_name as cn,
     movie_companies as mc,
     name as n,
     role_type as rt,
     title as t
where an.person_id = n.id
  and n.id = ci.person_id
  and ci.movie_id = t.id
  and t.id = mc.movie_id
  and mc.company_id = cn.id
  and ci.role_id = rt.id
  and an.person_id = ci.person_id
  and mc.note like '%(japan)%'
  and mc.note not like '%(usa)%'
  and (mc.note like '%(2006)%'
       or mc.note like '%(2007)%')
  and n.name like '%yo%'
  and n.name not like '%yu%'
  and cn.country_code ='[jp]'
  and ci.movie_id = mc.movie_id
  and rt.role = 'actor'
and t.title like 'date%'
and ci.note = '(voice: english version)'
and t.production_year between 1994  and 2008;