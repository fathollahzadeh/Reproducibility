select min(chn.name) as voiced_char_name,
       min(n.name) as voicing_actress_name,
       min(t.title) as kung_fu_panda
from aka_name as an,
     char_name as chn,
     cast_info as ci,
     company_name as cn,
     info_type as it,
     keyword as k,
     movie_companies as mc,
     movie_info as mi,
     movie_keyword as mk,
     name as n,
     role_type as rt,
     title as t
where ci.note in ('(voice)',
                  '(voice: japanese version)',
                  '(voice) (uncredited)',
                  '(voice: english version)')
  and cn.country_code ='[us]'
  and it.info = 'release dates'
  and mi.info is not null
  and (mi.info like 'japan:%201%'
       or mi.info like 'usa:%201%')
  and n.gender ='f'
  and n.name like '%an%'
  and rt.role ='actress'
  and t.id = mi.movie_id
  and t.id = mc.movie_id
  and t.id = ci.movie_id
  and t.id = mk.movie_id
  and mc.movie_id = ci.movie_id
  and mc.movie_id = mi.movie_id
  and mc.movie_id = mk.movie_id
  and mi.movie_id = ci.movie_id
  and mi.movie_id = mk.movie_id
  and ci.movie_id = mk.movie_id
  and cn.id = mc.company_id
  and it.id = mi.info_type_id
  and n.id = ci.person_id
  and rt.id = ci.role_id
  and n.id = an.person_id
  and ci.person_id = an.person_id
  and chn.id = ci.person_role_id
  and k.id = mk.keyword_id
  and t.title like 'kung fu panda%'
  and cn.name = 'dreamworks animation'
and k.keyword in ('second-part',
'female-nudity',
'web',
'kung-fu-master')
and t.production_year > 2009;