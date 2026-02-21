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
  and k.keyword in ('based-on-comic',
'based-on-comic',
'superhero',
'violence',
'fight',
'superhero',
'hero',
'sequel')
and n.name like '%smith,%'
and t.production_year > 1999;