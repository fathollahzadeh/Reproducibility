WITH filtered_keywords AS
  (SELECT mk.movie_id
   FROM movie_keyword mk
   JOIN keyword k ON mk.keyword_id = k.id
   WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital')),
     filtered_writers AS
  (SELECT ci.movie_id,
          n.name
   FROM cast_info ci
   JOIN name n ON ci.person_id = n.id
   WHERE n.gender = 'm'
     AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)'))
SELECT MIN(mi.info),
       MIN(mi_idx.info),
       MIN(fw.name),
       MIN(t.title)
FROM filtered_keywords fk
JOIN filtered_writers fw ON fk.movie_id = fw.movie_id
JOIN title t ON t.id = fk.movie_id
JOIN movie_info mi ON t.id = mi.movie_id
JOIN info_type it1 ON mi.info_type_id = it1.id
JOIN movie_info_idx mi_idx ON t.id = mi_idx.movie_id
JOIN info_type it2 ON mi_idx.info_type_id = it2.id
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN comp_cast_type cct1 ON cc.subject_id = cct1.id
JOIN comp_cast_type cct2 ON cc.status_id = cct2.id
WHERE mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND cct1.kind = 'cast'
  AND cct2.kind = 'complete+verified';