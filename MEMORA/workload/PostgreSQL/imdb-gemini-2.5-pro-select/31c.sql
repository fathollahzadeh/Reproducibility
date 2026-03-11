WITH filtered_mi AS
  (SELECT mi.movie_id,
          mi.info
   FROM movie_info AS mi
   JOIN info_type AS it1 ON it1.id = mi.info_type_id
   WHERE it1.info = 'genres'
     AND mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War')),
     filtered_mi_idx AS
  (SELECT mi_idx.movie_id,
          mi_idx.info
   FROM movie_info_idx AS mi_idx
   JOIN info_type AS it2 ON it2.id = mi_idx.info_type_id
   WHERE it2.info = 'votes'),
     filtered_mk AS
  (SELECT mk.movie_id
   FROM movie_keyword AS mk
   JOIN keyword AS k ON k.id = mk.keyword_id
   WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital')),
     filtered_mc AS
  (SELECT mc.movie_id
   FROM movie_companies AS mc
   JOIN company_name AS cn ON cn.id = mc.company_id
   WHERE cn.name LIKE 'Lionsgate%'),
     filtered_ci AS
  (SELECT ci.movie_id,
          ci.person_id
   FROM cast_info AS ci
   WHERE ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)'))
SELECT MIN(fmi.info),
       MIN(fmi_idx.info),
       MIN(n.name),
       MIN(t.title)
FROM filtered_mi AS fmi
JOIN filtered_mi_idx AS fmi_idx ON fmi.movie_id = fmi_idx.movie_id
JOIN filtered_mk AS fmk ON fmi.movie_id = fmk.movie_id
JOIN filtered_mc AS fmc ON fmi.movie_id = fmc.movie_id
JOIN filtered_ci AS fci ON fmi.movie_id = fci.movie_id
JOIN title AS t ON fmi.movie_id = t.id
JOIN name AS n ON fci.person_id = n.id;