select min(mi.info) as movie_budget,
       min(mi_idx.info) as movie_votes,
       min(n.name) as male_writer,
       min(t.title) as violent_movie_title
from cast_info as ci,
     info_type as it1,
     info_type as it2,
     keyword as k,
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
  and t.id = mi.movie_id
  and t.id = mi_idx.movie_id
  and t.id = ci.movie_id
  and t.id = mk.movie_id
  and ci.movie_id = mi.movie_id
  and ci.movie_id = mi_idx.movie_id
  and ci.movie_id = mk.movie_id
  and mi.movie_id = mi_idx.movie_id
  and mi.movie_id = mk.movie_id
  and mi_idx.movie_id = mk.movie_id
  and n.id = ci.person_id
  and it1.id = mi.info_type_id
  and it2.id = mi_idx.info_type_id
  and k.id = mk.keyword_id
  and t.title like '100%'
and k.keyword in ('claw',
'violence',
'sequel',
'fight',
'archive-footage')
and mi.info = 'documentary'
and n.gender = 'm'
and t.production_year > 1997;