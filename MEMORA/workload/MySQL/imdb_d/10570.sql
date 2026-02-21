select min(cn.name) as from_company,
       min(lt.link) as movie_link_type,
       min(t.title) as sequel_movie
from company_name as cn,
     company_type as ct,
     keyword as k,
     link_type as lt,
     movie_companies as mc,
     movie_keyword as mk,
     movie_link as ml,
     title as t
where lt.id = ml.link_type_id
  and ml.movie_id = t.id
  and t.id = mk.movie_id
  and mk.keyword_id = k.id
  and t.id = mc.movie_id
  and mc.company_type_id = ct.id
  and mc.company_id = cn.id
  and ml.movie_id = mk.movie_id
  and ml.movie_id = mc.movie_id
  and cn.country_code !='[pl]'
  and mc.note is null
  and (cn.name like '%film%'
       or cn.name like '%warner%')
  and ct.kind ='production companies'
  and lt.link like '%follows%'
  and mk.movie_id = mc.movie_id
  and t.title like '%by%'
and k.keyword = 'song';