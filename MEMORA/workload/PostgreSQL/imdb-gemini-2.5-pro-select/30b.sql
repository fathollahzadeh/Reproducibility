
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS writer,
       MIN(t.title) AS complete_gore_movie
FROM title AS t,
     movie_info AS mi,
     movie_info_idx AS mi_idx,
     cast_info AS ci,
     movie_keyword AS mk,
     complete_cast AS cc,
     name AS n,
     keyword AS k,
     info_type AS it1,
     info_type AS it2,
     comp_cast_type AS cct1,
     comp_cast_type AS cct2
WHERE t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND t.id = cc.movie_id
  AND n.id = ci.person_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id
  AND t.production_year > 2000
  AND (t.title LIKE 'Saw%'
       OR t.title LIKE '%Freddy%'
       OR t.title LIKE '%Jason%')
  AND n.gender = 'm'
  AND k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND cct1.kind IN ('cast', 'crew')
  AND cct2.kind = 'complete+verified'
  AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)')
  AND mi.info IN ('Horror', 'Thriller');