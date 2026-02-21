select min(cn.name) as company_name,
       min(lt.link) as link_type,
       min(t.title) as german_follow_up
from company_name as cn,
     company_type as ct,
     keyword as k,
     link_type as lt,
     movie_companies as mc,
     movie_info as mi,
     movie_keyword as mk,
     movie_link as ml,
     title as t
where (cn.name like '%film%'
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
  and ml.movie_id = mk.movie_id
  and ml.movie_id = mc.movie_id
  and mk.movie_id = mc.movie_id
  and ml.movie_id = mi.movie_id
  and mk.movie_id = mi.movie_id
  and mc.movie_id = mi.movie_id
  and mi.info in ('english',
'two patrolling cops stumble on to three criminals who have just stolen large amounts of explosives, and are killed in cold blood. martin beck and his team must now work day and night to find out who the killers are and what they are planning to do with the explosives before it''s too late. meanwhile, gunvald larsson who was a close friend of one of the murdered cops is ignoring all rules in his quest for revenge.')
and cn.country_code <> '[jp]'
and t.production_year between 1995  and 2005;