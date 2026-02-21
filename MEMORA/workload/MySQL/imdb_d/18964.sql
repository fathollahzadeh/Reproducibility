select min(mi.info) as movie_budget,
       min(mi_idx.info) as movie_votes,
       min(t.title) as movie_title
from cast_info as ci,
     info_type as it1,
     info_type as it2,
     movie_info as mi,
     movie_info_idx as mi_idx,
     name as n,
     title as t
where t.id = mi.movie_id
  and t.id = mi_idx.movie_id
  and t.id = ci.movie_id
  and ci.movie_id = mi.movie_id
  and ci.movie_id = mi_idx.movie_id
  and mi.movie_id = mi_idx.movie_id
  and n.id = ci.person_id
  and it1.id = mi.info_type_id
  and n.gender is not null
  and mi.note is null
  and it2.id = mi_idx.info_type_id
  and it1.info = 'genres'
  and it2.info = 'rating'
  and ci.note in ('(executive producer)',
'(writer)',
'(uncredited)',
'(producer)',
'(voice)')
and mi.info in ('action',
'sci-fi')
and mi_idx.info > '6.9'
and n.gender = 'm'
and t.production_year between 2001  and 2009;