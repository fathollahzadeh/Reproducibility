select min(cn.name) as producing_company,
       min(miidx.info) as rating,
       min(t.title) as movie
from company_name as cn,
     company_type as ct,
     info_type as it,
     info_type as it2,
     kind_type as kt,
     movie_companies as mc,
     movie_info as mi,
     movie_info_idx as miidx,
     title as t
where it.info ='rating'
  and it2.info ='release dates'
  and mi.movie_id = t.id
  and it2.id = mi.info_type_id
  and kt.id = t.kind_id
  and mc.movie_id = t.id
  and cn.id = mc.company_id
  and ct.id = mc.company_type_id
  and miidx.movie_id = t.id
  and it.id = miidx.info_type_id
  and mi.movie_id = miidx.movie_id
  and mi.movie_id = mc.movie_id
  and miidx.movie_id = mc.movie_id
  and ct.kind = 'distributors'
and kt.kind = 'tv series'
and cn.country_code = '[ca]';