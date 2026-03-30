SELECT MIN("t4"."info") AS "movie_budget", MIN("movie_info_idx"."info") AS "movie_votes", MIN("t5"."name") AS "writer", MIN("title"."title") AS "violent_liongate_movie"
FROM (SELECT *
FROM "cast_info"
WHERE "note" IN ('(head writer)', '(story editor)', '(story)', '(writer)', '(written by)')) AS "t"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "name" LIKE 'Lionsgate%') AS "t0"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'genres') AS "t1"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'votes') AS "t2"
CROSS JOIN (SELECT *
FROM "keyword"
WHERE "keyword" IN ('blood', 'death', 'female-nudity', 'gore', 'hospital', 'murder', 'violence')) AS "t3"
INNER JOIN "movie_companies" ON "t"."movie_id" = "movie_companies"."movie_id" AND "t0"."id" = "movie_companies"."company_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "info" IN ('Horror', 'Thriller')) AS "t4" ON "t"."movie_id" = "t4"."movie_id" AND "t1"."id" = "t4"."info_type_id"
INNER JOIN "movie_info_idx" ON "t"."movie_id" = "movie_info_idx"."movie_id" AND "t2"."id" = "movie_info_idx"."info_type_id"
INNER JOIN "movie_keyword" ON "t"."movie_id" = "movie_keyword"."movie_id" AND "t3"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "gender" = 'm') AS "t5" ON "t"."person_id" = "t5"."id"
INNER JOIN "title" ON "t4"."movie_id" = "title"."id"