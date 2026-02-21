select min(k.keyword) as movie_keyword,
       min(n.name) as actor_name,
       min(t.title) as hero_movie
from cast_info as ci,
     keyword as k,
     movie_keyword as mk,
     name as n,
     title as t
where k.id = mk.keyword_id
  and t.id = mk.movie_id
  and t.id = ci.movie_id
  and ci.movie_id = mk.movie_id
  and n.id = ci.person_id
  and k.keyword in ('sequel',
'laser',
'marvel-comics',
'superhero',
'sequel',
'violence',
'based-on-comic',
'claw')
and n.name like '%jones,%'
and t.production_year > 1995;