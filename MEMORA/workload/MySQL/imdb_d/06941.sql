select min(mi.info) as movie_budget,
       min(mi_idx.info) as movie_votes,
       min(n.name) as writer,
       min(t.title) as complete_violent_movie
from complete_cast as cc,
     comp_cast_type as cct1,
     comp_cast_type as cct2,
     cast_info as ci,
     info_type as it1,
     info_type as it2,
     keyword as k,
     movie_info as mi,
     movie_info_idx as mi_idx,
     movie_keyword as mk,
     name as n,
     title as t
where cct2.kind ='complete+verified'
  and ci.note in ('(writer)',
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
  and n.gender = 'm'
  and t.id = mi.movie_id
  and t.id = mi_idx.movie_id
  and t.id = ci.movie_id
  and t.id = mk.movie_id
  and t.id = cc.movie_id
  and ci.movie_id = mi.movie_id
  and ci.movie_id = mi_idx.movie_id
  and ci.movie_id = mk.movie_id
  and ci.movie_id = cc.movie_id
  and mi.movie_id = mi_idx.movie_id
  and mi.movie_id = mk.movie_id
  and mi.movie_id = cc.movie_id
  and mi_idx.movie_id = mk.movie_id
  and mi_idx.movie_id = cc.movie_id
  and mk.movie_id = cc.movie_id
  and n.id = ci.person_id
  and it1.id = mi.info_type_id
  and it2.id = mi_idx.info_type_id
  and k.id = mk.keyword_id
  and cct1.id = cc.subject_id
  and cct2.id = cc.status_id
  and cct1.kind in ('complete',
'cast')
and mi.info in ('western',
'crime')
and t.production_year > 2001;