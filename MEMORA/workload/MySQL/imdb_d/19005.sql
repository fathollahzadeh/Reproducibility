select min(mi.info) as budget,
       min(t.title) as unsuccsessful_movie
from company_name as cn,
     company_type as ct,
     info_type as it1,
     info_type as it2,
     movie_companies as mc,
     movie_info as mi,
     movie_info_idx as mi_idx,
     title as t
where cn.country_code ='[us]'
  and t.id = mi.movie_id
  and t.id = mi_idx.movie_id
  and mi.info_type_id = it1.id
  and mi_idx.info_type_id = it2.id
  and t.id = mc.movie_id
  and ct.id = mc.company_type_id
  and cn.id = mc.company_id
  and mc.movie_id = mi.movie_id
  and mc.movie_id = mi_idx.movie_id
  and ct.kind is not null
  and (t.title like 'birdemic%'
       or t.title like '%movie%')
  and it1.info ='budget'
  and it2.info ='bottom 10 rank'
  and mi.movie_id = mi_idx.movie_id
  and (ct.kind ='production companies'
       or ct.kind = 'distributors')
  and t.production_year > 2007;