select min(t.title) as movie_title
from keyword as k,
     movie_info as mi,
     movie_keyword as mk,
     title as t
where k.keyword like '%sequel%'
  and t.id = mi.movie_id
  and t.id = mk.movie_id
  and mk.movie_id = mi.movie_id
  and k.id = mk.keyword_id
  and mi.info in ('bulgaria',
'german',
'norway',
'danish',
'swedish',
'sweden',
'denish',
'usa',
'denmark',
'america')
and t.production_year > 2006;