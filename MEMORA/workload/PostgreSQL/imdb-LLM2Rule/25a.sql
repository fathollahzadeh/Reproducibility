SELECT MIN("t3"."info") AS "movie_budget", MIN("movie_info_idx"."info") AS "movie_votes", MIN("t4"."name") AS "male_writer", MIN("title"."title") AS "violent_movie_title"
FROM (SELECT *
FROM "cast_info"
WHERE "note" IN ('(head writer)', '(story editor)', '(story)', '(writer)', '(written by)')) AS "t"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'genres') AS "t0"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'votes') AS "t1"
CROSS JOIN (SELECT *
FROM "keyword"
WHERE "keyword" IN ('blood', 'death', 'female-nudity', 'gore', 'murder')) AS "t2"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "info" = 'Horror') AS "t3" ON "t"."movie_id" = "t3"."movie_id" AND "t0"."id" = "t3"."info_type_id"
INNER JOIN "movie_info_idx" ON "t"."movie_id" = "movie_info_idx"."movie_id" AND "t1"."id" = "movie_info_idx"."info_type_id"
INNER JOIN "movie_keyword" ON "t"."movie_id" = "movie_keyword"."movie_id" AND "t2"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "gender" = 'm') AS "t4" ON "t"."person_id" = "t4"."id"
INNER JOIN "title" ON "t3"."movie_id" = "title"."id"