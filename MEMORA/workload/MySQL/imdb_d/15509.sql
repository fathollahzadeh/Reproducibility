select min(mi.info) as movie_budget,
       min(mi_idx.info) as movie_votes,
       min(n.name) as writer,
       min(t.title) as violent_liongate_movie
from cast_info as ci,
     company_name as cn,
     info_type as it1,
     info_type as it2,
     keyword as k,
     movie_companies as mc,
     movie_info as mi,
     movie_info_idx as mi_idx,
     movie_keyword as mk,
     name as n,
     title as t
where ci.note in ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  and it1.info = 'genres'
  and it2.info = 'votes'
  and k.keyword in ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital')
  and t.id = mi.movie_id
  and t.id = mi_idx.movie_id
  and t.id = ci.movie_id
  and t.id = mk.movie_id
  and t.id = mc.movie_id
  and ci.movie_id = mi.movie_id
  and ci.movie_id = mi_idx.movie_id
  and ci.movie_id = mk.movie_id
  and ci.movie_id = mc.movie_id
  and mi.movie_id = mi_idx.movie_id
  and mi.movie_id = mk.movie_id
  and mi.movie_id = mc.movie_id
  and mi_idx.movie_id = mk.movie_id
  and mi_idx.movie_id = mc.movie_id
  and mk.movie_id = mc.movie_id
  and n.id = ci.person_id
  and it1.id = mi.info_type_id
  and it2.id = mi_idx.info_type_id
  and k.id = mk.keyword_id
  and (t.title like '%freddy%'
       or t.title like '%jason%'
       or t.title like 'saw%')
  and cn.id = mc.company_id
  and cn.name like 'rcv%'
and mc.note like '%(2003)%'
and mi.info in ('drama',
'crime')
and n.gender = 'm'
and t.production_year > 2001;