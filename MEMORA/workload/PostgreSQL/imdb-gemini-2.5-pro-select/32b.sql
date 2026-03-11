WITH KeywordMovies AS
  (SELECT mk.movie_id,
          t.title AS first_movie_title
   FROM keyword AS k
   JOIN movie_keyword AS mk ON k.id = mk.keyword_id
   JOIN title AS t ON mk.movie_id = t.id
   WHERE k.keyword = 'character-name-in-title')
SELECT MIN(lt.link),
       MIN(km.first_movie_title),
       MIN(t2.title)
FROM KeywordMovies AS km
JOIN movie_link AS ml ON km.movie_id = ml.movie_id
JOIN title AS t2 ON ml.linked_movie_id = t2.id
JOIN link_type AS lt ON ml.link_type_id = lt.id;