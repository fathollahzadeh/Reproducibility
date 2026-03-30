SELECT MIN("t1"."info") AS "rating", MIN("t2"."title") AS "movie_title"
FROM (SELECT *
FROM "info_type"
WHERE "info" = 'rating') AS "t"
CROSS JOIN (SELECT *
FROM "keyword"
WHERE "keyword" LIKE '%sequel%') AS "t0"
INNER JOIN (SELECT *
FROM "movie_info_idx"
WHERE "info" > '9.0') AS "t1" ON "t"."id" = "t1"."info_type_id"
INNER JOIN "movie_keyword" ON "t1"."movie_id" = "movie_keyword"."movie_id" AND "t0"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2010) AS "t2" ON "t1"."movie_id" = "t2"."id"