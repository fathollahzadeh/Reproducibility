
SELECT MIN(lt.link),
       MIN(t1.title),
       MIN(t2.title)
FROM keyword AS k
JOIN movie_keyword AS mk ON k.id = mk.keyword_id
JOIN title AS t1 ON mk.movie_id = t1.id
JOIN movie_link AS ml ON t1.id = ml.movie_id
JOIN title AS t2 ON ml.linked_movie_id = t2.id
JOIN link_type AS lt ON ml.link_type_id = lt.id
WHERE k.keyword = '10,000-mile-club';