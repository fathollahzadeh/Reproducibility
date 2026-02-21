select min(mi.info) as release_date,
       min(t.title) as youtube_movie
from aka_title as at,
     company_name as cn,
     company_type as ct,
     info_type as it1,
     keyword as k,
     movie_companies as mc,
     movie_info as mi,
     movie_keyword as mk,
     title as t
where cn.country_code = '[us]'
  and mi.note like '%internet%'
  and it1.info = 'release dates'
  and t.id = at.movie_id
  and t.id = mi.movie_id
  and t.id = mk.movie_id
  and t.id = mc.movie_id
  and mk.movie_id = mi.movie_id
  and mk.movie_id = mc.movie_id
  and mk.movie_id = at.movie_id
  and mi.movie_id = mc.movie_id
  and mi.movie_id = at.movie_id
  and mc.movie_id = at.movie_id
  and k.id = mk.keyword_id
  and it1.id = mi.info_type_id
  and cn.id = mc.company_id
  and mi.info like 'usa:% 200%'
  and mc.note like '%(200%)%'
  and mc.note like '%(worldwide)%'
  and ct.id = mc.company_type_id
  and cn.name = 'ea mobile'
and t.production_year between 2000  and 2006;