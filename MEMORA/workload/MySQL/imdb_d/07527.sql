select min(n.name) as voicing_actress,
       min(t.title) as jap_engl_voiced_movie
from aka_name as an,
     char_name as chn,
     cast_info as ci,
     company_name as cn,
     info_type as it,
     movie_companies as mc,
     movie_info as mi,
     name as n,
     role_type as rt,
     title as t
where cn.country_code ='[us]'
  and it.info = 'release dates'
  and n.gender ='f'
  and rt.role ='actress'
  and t.id = mi.movie_id
  and t.id = mc.movie_id
  and t.id = ci.movie_id
  and mc.movie_id = ci.movie_id
  and mc.movie_id = mi.movie_id
  and mi.movie_id = ci.movie_id
  and cn.id = mc.company_id
  and it.id = mi.info_type_id
  and n.id = ci.person_id
  and rt.id = ci.role_id
  and n.id = an.person_id
  and ci.person_id = an.person_id
  and chn.id = ci.person_role_id
  and ci.note in ('(uncredited)',
'(executive producer)',
'(producer)',
'(as allison) (credit only)')
and t.production_year > 2006;