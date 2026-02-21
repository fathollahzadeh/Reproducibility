select min(t.title) as typical_european_movie
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
  and mc.note like '%(theatrical)%'
  and mc.note like '%(france)%'
  and it.id = mi.info_type_id
  and mi.info in ('bulgaria',
'germany',
'german',
'norway',
'english',
'america',
'denish',
'norwegian');