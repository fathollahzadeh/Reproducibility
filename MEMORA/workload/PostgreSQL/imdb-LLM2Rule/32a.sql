SELECT MIN("link_type"."link") AS "link_type", MIN("title"."title") AS "first_movie", MIN("title0"."title") AS "second_movie"
FROM (SELECT *
FROM "keyword"
WHERE "keyword" = '10,000-mile-club') AS "t"
CROSS JOIN "link_type"
INNER JOIN "movie_keyword" ON "t"."id" = "movie_keyword"."keyword_id"
INNER JOIN "movie_link" ON "link_type"."id" = "movie_link"."link_type_id" AND "movie_keyword"."movie_id" = "movie_link"."movie_id"
INNER JOIN "title" ON "movie_keyword"."movie_id" = "title"."id"
INNER JOIN "title" AS "title0" ON "movie_link"."linked_movie_id" = "title0"."id"