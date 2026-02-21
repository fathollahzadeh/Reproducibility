select min(mc.note) as production_note,
       min(t.title) as movie_title,
       min(t.production_year) as movie_year
from company_type as ct,
     info_type as it,
     movie_companies as mc,
     movie_info_idx as mi_idx,
     title as t
where ct.kind = 'production companies'
  and mc.note not like '%(as metro-goldwyn-mayer pictures)%'
  and ct.id = mc.company_type_id
  and t.id = mc.movie_id
  and t.id = mi_idx.movie_id
  and mc.movie_id = mi_idx.movie_id
  and it.info = 'bottom 10 rank'
  and it.id = mi_idx.info_type_id
  and t.production_year between 1994  and 2004;