select min(n.name) as cast_member,
       min(t.title) as complete_dynamic_hero_movie
from complete_cast as cc,
     comp_cast_type as cct1,
     comp_cast_type as cct2,
     char_name as chn,
     cast_info as ci,
     keyword as k,
     kind_type as kt,
     movie_keyword as mk,
     name as n,
     title as t
where cct1.kind = 'cast'
  and cct2.kind like '%complete%'
  and chn.name is not null
  and kt.kind = 'movie'
  and kt.id = t.kind_id
  and t.id = mk.movie_id
  and t.id = ci.movie_id
  and t.id = cc.movie_id
  and mk.movie_id = ci.movie_id
  and mk.movie_id = cc.movie_id
  and ci.movie_id = cc.movie_id
  and chn.id = ci.person_role_id
  and n.id = ci.person_id
  and k.id = mk.keyword_id
  and cct1.id = cc.subject_id
  and cct2.id = cc.status_id
  and (chn.name like '%andrés%'
or chn.name like '%andrés%')
and t.production_year > 1958
and k.keyword in ('violence',
'marvel-comics',
'second-part',
'revenge',
'hero',
'sequel',
'superhero',
'murder-in-title',
'martial-arts',
'number-in-title');