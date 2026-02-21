select min(t.title) as complete_downey_ironman_movie
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
  and chn.name not like '%sherlock%'
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
  and n.name like '%encarnita%'
and t.production_year > 1964
and chn.name like '%adriana%'
and k.keyword in ('hero',
'10,000-mile-club',
'tv-special',
'laser',
'marvel-cinematic-universe',
'sequel',
'death',
'movie-spoof');