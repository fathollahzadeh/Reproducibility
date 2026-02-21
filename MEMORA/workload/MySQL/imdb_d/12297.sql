select min(mi_idx.info) as rating,
       min(t.title) as northern_dark_movie
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
  and it2.id = mi_idx.info_type_id
  and k.keyword in ('superhero',
'web',
'blood',
'funny-nazi')
and kt.kind = 'tv series'
and mi.info in ('germany',
'america',
'sweden',
'danish',
'usa',
'norwegian',
'american',
'swedish',
'german',
'uk')
and mi_idx.info < '7.0'
and t.production_year > 1980;