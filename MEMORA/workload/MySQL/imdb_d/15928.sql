select min(t.title) as movie_title
from company_name as cn,
     keyword as k,
     movie_companies as mc,
     movie_keyword as mk,
     title as t
where k.keyword ='character-name-in-title'
  and cn.id = mc.company_id
  and mc.movie_id = t.id
  and t.id = mk.movie_id
  and mk.keyword_id = k.id
  and mc.movie_id = mk.movie_id
  and cn.country_code = '[im]';