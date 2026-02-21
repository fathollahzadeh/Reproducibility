select min(cn.name) as company_name,
       min(lt.link) as link_type,
       min(t.title) as western_follow_up
from company_name as cn,
     company_type as ct,
     keyword as k,
     link_type as lt,
     movie_companies as mc,
     movie_info as mi,
     movie_keyword as mk,
     movie_link as ml,
     title as t
where (cn.name like '%film%'
       or cn.name like '%warner%')
  and ct.kind ='production companies'
  and k.keyword ='sequel'
  and lt.link like '%follow%'
  and mc.note is null
  and lt.id = ml.link_type_id
  and ml.movie_id = t.id
  and t.id = mk.movie_id
  and mk.keyword_id = k.id
  and t.id = mc.movie_id
  and mc.company_type_id = ct.id
  and mc.company_id = cn.id
  and mi.movie_id = t.id
  and ml.movie_id = mk.movie_id
  and ml.movie_id = mc.movie_id
  and mk.movie_id = mc.movie_id
  and ml.movie_id = mi.movie_id
  and mk.movie_id = mi.movie_id
  and mc.movie_id = mi.movie_id
  and mi.info in ('english',
'sweden',
'norway',
'denmark',
'danish',
'germany',
'usa',
'america')
and cn.country_code <> '[ru]'
and t.production_year between 1995  and 2011;