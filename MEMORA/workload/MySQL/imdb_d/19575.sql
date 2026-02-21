select min(kt.kind) as movie_kind,
       min(t.title) as complete_nerdy_internet_movie
from complete_cast as cc,
     comp_cast_type as cct1,
     company_name as cn,
     company_type as ct,
     info_type as it1,
     keyword as k,
     kind_type as kt,
     movie_companies as mc,
     movie_info as mi,
     movie_keyword as mk,
     title as t
where cct1.kind = 'complete+verified'
  and it1.info = 'release dates'
  and k.keyword in ('nerd',
                    'loner',
                    'alienation',
                    'dignity')
  and mi.note like '%internet%'
  and mi.info like 'usa:% 200%'
  and kt.id = t.kind_id
  and t.id = mi.movie_id
  and t.id = mk.movie_id
  and t.id = mc.movie_id
  and t.id = cc.movie_id
  and mk.movie_id = mi.movie_id
  and mk.movie_id = mc.movie_id
  and mk.movie_id = cc.movie_id
  and mi.movie_id = mc.movie_id
  and mi.movie_id = cc.movie_id
  and mc.movie_id = cc.movie_id
  and k.id = mk.keyword_id
  and it1.id = mi.info_type_id
  and cn.id = mc.company_id
  and ct.id = mc.company_type_id
  and cct1.id = cc.status_id
  and kt.kind in ('movie')
  and cn.country_code = '[us]'
  and t.production_year > 2012;