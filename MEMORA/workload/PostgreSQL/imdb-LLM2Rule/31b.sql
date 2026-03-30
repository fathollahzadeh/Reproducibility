SELECT MIN("t5"."info") AS "movie_budget", MIN("movie_info_idx"."info") AS "movie_votes", MIN("t6"."name") AS "writer", MIN("t7"."title") AS "violent_liongate_movie"
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
INNER JOIN (SELECT *
FROM "movie_companies"
WHERE "note" LIKE '%(Blu-ray)%') AS "t4" ON "t"."movie_id" = "t4"."movie_id" AND "t0"."id" = "t4"."company_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "info" IN ('Horror', 'Thriller')) AS "t5" ON "t"."movie_id" = "t5"."movie_id" AND "t1"."id" = "t5"."info_type_id"
INNER JOIN "movie_info_idx" ON "t"."movie_id" = "movie_info_idx"."movie_id" AND "t2"."id" = "movie_info_idx"."info_type_id"
INNER JOIN "movie_keyword" ON "t"."movie_id" = "movie_keyword"."movie_id" AND "t3"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "gender" = 'm') AS "t6" ON "t"."person_id" = "t6"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2000 AND ("title" LIKE '%Freddy%' OR "title" LIKE '%Jason%' OR "title" LIKE 'Saw%')) AS "t7" ON "t5"."movie_id" = "t7"."id"