select min(mi_idx.info) as rating,
       min(t.title) as north_european_dark_production
from info_type as it1,
     info_type as it2,
     keyword as k,
     kind_type as kt,
     movie_info as mi,
     movie_info_idx as mi_idx,
     movie_keyword as mk,
     title as t
where it1.info = 'countries'
  and it2.info = 'rating'
  and kt.id = t.kind_id
  and t.id = mi.movie_id
  and t.id = mk.movie_id
  and t.id = mi_idx.movie_id
  and mk.movie_id = mi.movie_id
  and mk.movie_id = mi_idx.movie_id
  and mi.movie_id = mi_idx.movie_id
  and k.id = mk.keyword_id
  and it1.id = mi.info_type_id
  and k.keyword is not null
  and it2.id = mi_idx.info_type_id
  and k.keyword in ('violence',
'murder',
'violence',
'digit-in-title')
and kt.kind in ('episode',
'tv series')
and mi.info in ('danish',
'american',
'bulgaria',
'america',
'norwegian',
'denmark',
'swedish',
'norway',
'german',
'usa')
and mi_idx.info < '8'
and t.production_year > 2001;