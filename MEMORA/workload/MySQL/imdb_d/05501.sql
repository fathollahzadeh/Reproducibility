select min(t.title) as american_movie
from company_type as ct,
     info_type as it,
     movie_companies as mc,
     movie_info as mi,
     title as t
where ct.kind = 'production companies'
  and t.id = mi.movie_id
  and t.id = mc.movie_id
  and mc.movie_id = mi.movie_id
  and ct.id = mc.company_type_id
  and it.id = mi.info_type_id
  and mc.note not like '%(tv)%'
  and mc.note like '%(usa)%'
  and mi.info in ('sweden',
'america',
'danish',
'english',
'norway',
'swedish',
'american',
'germany',
'bulgaria',
'norwegian')
and t.production_year > 2000;