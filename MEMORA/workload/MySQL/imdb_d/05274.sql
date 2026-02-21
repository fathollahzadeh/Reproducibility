select min(mi_idx.info) as rating,
       min(t.title) as movie_title
from info_type as it,
     keyword as k,
     movie_info_idx as mi_idx,
     movie_keyword as mk,
     title as t
where it.info ='rating'
  and k.keyword like '%sequel%'
  and t.id = mi_idx.movie_id
  and t.id = mk.movie_id
  and mk.movie_id = mi_idx.movie_id
  and k.id = mk.keyword_id
  and it.id = mi_idx.info_type_id
  and mi_idx.info > '6.1'
and t.production_year > 1994;