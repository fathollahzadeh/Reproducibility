SELECT MIN("movie_info"."info") AS "budget", MIN("t3"."title") AS "unsuccsessful_movie"
FROM (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t"
CROSS JOIN (SELECT *
FROM "company_type"
WHERE "kind" IN ('distributors', 'production companies')) AS "t0"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'budget') AS "t1"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'bottom 10 rank') AS "t2"
INNER JOIN "movie_companies" ON "t0"."id" = "movie_companies"."company_type_id" AND "t"."id" = "movie_companies"."company_id"
INNER JOIN "movie_info" ON "t1"."id" = "movie_info"."info_type_id" AND "movie_companies"."movie_id" = "movie_info"."movie_id"
INNER JOIN "movie_info_idx" ON "t2"."id" = "movie_info_idx"."info_type_id" AND "movie_companies"."movie_id" = "movie_info_idx"."movie_id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2000 AND ("title" LIKE 'Birdemic%' OR "title" LIKE '%Movie%')) AS "t3" ON "movie_info"."movie_id" = "t3"."id"