select min(cn1.name) as first_company,
       min(cn2.name) as second_company,
       min(mi_idx1.info) as first_rating,
       min(mi_idx2.info) as second_rating,
       min(t1.title) as first_movie,
       min(t2.title) as second_movie
from company_name as cn1,
     company_name as cn2,
     info_type as it1,
     info_type as it2,
     kind_type as kt1,
     kind_type as kt2,
     link_type as lt,
     movie_companies as mc1,
     movie_companies as mc2,
     movie_info_idx as mi_idx1,
     movie_info_idx as mi_idx2,
     movie_link as ml,
     title as t1,
     title as t2
where it1.info = 'rating'
  and it2.info = 'rating'
  and lt.id = ml.link_type_id
  and t1.id = ml.movie_id
  and t2.id = ml.linked_movie_id
  and it1.id = mi_idx1.info_type_id
  and t1.id = mi_idx1.movie_id
  and kt1.id = t1.kind_id
  and cn1.id = mc1.company_id
  and t1.id = mc1.movie_id
  and ml.movie_id = mi_idx1.movie_id
  and ml.movie_id = mc1.movie_id
  and mi_idx1.movie_id = mc1.movie_id
  and it2.id = mi_idx2.info_type_id
  and t2.id = mi_idx2.movie_id
  and kt2.id = t2.kind_id
  and cn2.id = mc2.company_id
  and t2.id = mc2.movie_id
  and ml.linked_movie_id = mi_idx2.movie_id
  and ml.linked_movie_id = mc2.movie_id
  and kt1.kind in ('tv series')
  and kt2.kind in ('tv series')
  and mi_idx2.movie_id = mc2.movie_id
  and mi_idx2.info < '6.9'
and cn1.country_code = '[de]'
and t2.production_year between 1995  and 2002
and lt.link in ('remade as',
'features',
'spoofs');