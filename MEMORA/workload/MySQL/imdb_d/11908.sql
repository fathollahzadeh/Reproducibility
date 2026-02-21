select min(cn.name) as producing_company,
       min(lt.link) as link_type,
       min(t.title) as complete_western_sequel
from complete_cast as cc,
     comp_cast_type as cct1,
     comp_cast_type as cct2,
     company_name as cn,
     company_type as ct,
     keyword as k,
     link_type as lt,
     movie_companies as mc,
     movie_info as mi,
     movie_keyword as mk,
     movie_link as ml,
     title as t
where cct2.kind = 'complete'
  and cn.country_code !='[pl]'
  and (cn.name like '%film%'
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
  and t.id = cc.movie_id
  and cct1.id = cc.subject_id
  and cct2.id = cc.status_id
  and ml.movie_id = mk.movie_id
  and ml.movie_id = mc.movie_id
  and mk.movie_id = mc.movie_id
  and ml.movie_id = mi.movie_id
  and mk.movie_id = mi.movie_id
  and mc.movie_id = mi.movie_id
  and ml.movie_id = cc.movie_id
  and mk.movie_id = cc.movie_id
  and mc.movie_id = cc.movie_id
  and mi.movie_id = cc.movie_id
  and t.production_year between 1996  and 2012
and mi.info in ('german',
'norway',
'american',
'color')
and cct1.kind in ('cast',
'cast');