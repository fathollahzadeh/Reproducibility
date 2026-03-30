SELECT MIN("t1"."title") AS "movie_title"
FROM (SELECT *
FROM "keyword"
WHERE "keyword" LIKE '%sequel%') AS "t"
CROSS JOIN (SELECT *
FROM "movie_info"
WHERE "info" = 'Bulgaria') AS "t0"
INNER JOIN "movie_keyword" ON "t0"."movie_id" = "movie_keyword"."movie_id" AND "t"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2010) AS "t1" ON "t0"."movie_id" = "t1"."id"