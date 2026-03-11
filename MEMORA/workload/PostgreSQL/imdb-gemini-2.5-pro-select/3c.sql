
SELECT MIN(t.title)
FROM title AS t
WHERE t.production_year > 1990
  AND t.id IN
    (SELECT movie_id
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE k.keyword LIKE '%sequel%')
  AND t.id IN
    (SELECT movie_id
     FROM movie_info
     WHERE info IN ('Sweden', 'Norway', 'Germany', 'Denmark', 'Swedish', 'Denish', 'Norwegian', 'German', 'USA', 'American'));