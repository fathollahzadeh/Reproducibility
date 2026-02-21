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
  and mi.info in ('sweden',
'swedish',
'norwegian',
'german',
'usa',
'norway',
'english',
'denmark')
and t.production_year > 2005;