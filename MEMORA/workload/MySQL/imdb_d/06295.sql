select min(cn.name) as movie_company,
       min(mi_idx.info) as rating,
       min(t.title) as complete_euro_dark_movie
from complete_cast as cc,
     comp_cast_type as cct1,
     comp_cast_type as cct2,
     company_name as cn,
     company_type as ct,
     info_type as it1,
     info_type as it2,
     keyword as k,
     kind_type as kt,
     movie_companies as mc,
     movie_info as mi,
     movie_info_idx as mi_idx,
     movie_keyword as mk,
     title as t
where cct1.kind = 'crew'
  and cct2.kind != 'complete+verified'
  and cn.country_code != '[us]'
  and it1.info = 'countries'
  and it2.info = 'rating'
  and k.keyword in ('murder',
                    'murder-in-title',
                    'blood',
                    'violence')
  and kt.kind in ('movie',
                  'episode')
  and mc.note not like '%(usa)%'
  and mc.note like '%(200%)%'
  and mi_idx.info < '8.5'
  and kt.id = t.kind_id
  and t.id = mi.movie_id
  and t.id = mk.movie_id
  and t.id = mi_idx.movie_id
  and t.id = mc.movie_id
  and t.id = cc.movie_id
  and mk.movie_id = mi.movie_id
  and mk.movie_id = mi_idx.movie_id
  and mk.movie_id = mc.movie_id
  and mk.movie_id = cc.movie_id
  and mi.movie_id = mi_idx.movie_id
  and mi.movie_id = mc.movie_id
  and mi.movie_id = cc.movie_id
  and mc.movie_id = mi_idx.movie_id
  and mc.movie_id = cc.movie_id
  and mi_idx.movie_id = cc.movie_id
  and k.id = mk.keyword_id
  and it1.id = mi.info_type_id
  and it2.id = mi_idx.info_type_id
  and ct.id = mc.company_type_id
  and cn.id = mc.company_id
  and cct1.id = cc.subject_id
  and cct2.id = cc.status_id
  and t.production_year > 2000
and mi.info in ('denmark',
'english',
'norway',
'usa',
'swedish',
'bulgaria',
'danish',
'america',
'sweden',
'american');