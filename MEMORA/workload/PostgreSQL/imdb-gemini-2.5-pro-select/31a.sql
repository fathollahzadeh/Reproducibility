WITH movies_by_company AS
  (SELECT mc.movie_id
   FROM company_name AS cn
   JOIN movie_companies AS mc ON cn.id = mc.company_id
   WHERE cn.name LIKE 'Lionsgate%'),
     movies_by_keyword AS
  (SELECT mk.movie_id
   FROM keyword AS k
   JOIN movie_keyword AS mk ON k.id = mk.keyword_id
   WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital')),
     movies_by_info1 AS
  (SELECT mi.movie_id,
          mi.info
   FROM info_type AS it1
   JOIN movie_info AS mi ON it1.id = mi.info_type_id
   WHERE it1.info = 'genres'
     AND mi.info IN ('Horror', 'Thriller')),
     movies_by_info2 AS
  (SELECT mi_idx.movie_id,
          mi_idx.info
   FROM info_type AS it2
   JOIN movie_info_idx AS mi_idx ON it2.id = mi_idx.info_type_id
   WHERE it2.info = 'votes'),
     movies_by_cast AS
  (SELECT ci.movie_id,
          n.name
   FROM name AS n
   JOIN cast_info AS ci ON n.id = ci.person_id
   WHERE n.gender = 'm'
     AND ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)'))
SELECT MIN(mi1.info) AS movie_budget,
       MIN(mi2.info) AS movie_votes,
       MIN(mc.name) AS writer,
       MIN(t.title) AS violent_liongate_movie
FROM title AS t
JOIN movies_by_company AS mbc ON t.id = mbc.movie_id
JOIN movies_by_keyword AS mbk ON t.id = mbk.movie_id
JOIN movies_by_info1 AS mi1 ON t.id = mi1.movie_id
JOIN movies_by_info2 AS mi2 ON t.id = mi2.movie_id
JOIN movies_by_cast AS mc ON t.id = mc.movie_id;