select min(t.title) as american_vhs_movie
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
  and mc.note like '%(vhs)%'
  and mc.note like '%(usa)%'
  and mc.note like '%(1994)%'
  and it.id = mi.info_type_id
  and mi.info in ('norway',
'norwegian')
and t.production_year > 2004;