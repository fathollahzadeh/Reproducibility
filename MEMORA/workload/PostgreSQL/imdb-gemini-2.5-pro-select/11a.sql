WITH keyword_filtered AS
  (SELECT mk.movie_id
   FROM keyword k
   JOIN movie_keyword mk ON k.id = mk.keyword_id
   WHERE k.keyword = 'sequel'),
     link_filtered AS
  (SELECT ml.movie_id,
          lt.link
   FROM link_type lt
   JOIN movie_link ml ON lt.id = ml.link_type_id
   WHERE lt.link LIKE '%follow%'),
     movies_base AS
  (SELECT kf.movie_id,
          lf.link
   FROM keyword_filtered kf
   JOIN link_filtered lf ON kf.movie_id = lf.movie_id)
SELECT MIN(cn.name),
       MIN(mb.link),
       MIN(t.title)
FROM movies_base mb
JOIN title t ON mb.movie_id = t.id
AND t.production_year BETWEEN 1950 AND 2000
JOIN movie_companies mc ON mb.movie_id = mc.movie_id
AND mc.note IS NULL
JOIN company_type ct ON mc.company_type_id = ct.id
AND ct.kind = 'production companies'
JOIN company_name cn ON mc.company_id = cn.id
AND cn.country_code != '[pl]'
AND (cn.name LIKE '%Film%'
     OR cn.name LIKE '%Warner%');