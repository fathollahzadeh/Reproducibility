select min(cn.name) as from_company,
       min(mc.note) as production_note,
       min(t.title) as movie_based_on_book
from company_name as cn,
     company_type as ct,
     keyword as k,
     link_type as lt,
     movie_companies as mc,
     movie_keyword as mk,
     movie_link as ml,
     title as t
where cn.country_code !='[pl]'
  and lt.id = ml.link_type_id
  and ml.movie_id = t.id
  and t.id = mk.movie_id
  and mk.keyword_id = k.id
  and t.id = mc.movie_id
  and mc.company_type_id = ct.id
  and mc.company_id = cn.id
  and ml.movie_id = mk.movie_id
  and ml.movie_id = mc.movie_id
  and ct.kind is not null
  and mc.note is not null
  and mk.movie_id = mc.movie_id
  and (cn.name like '20th century fox%'
       or cn.name like 'twentieth century fox%')
  and ct.kind <> 'special effects companies'
and k.keyword in ('murder',
'tv-special',
'buried-under-a-building')
and t.production_year > 2009;