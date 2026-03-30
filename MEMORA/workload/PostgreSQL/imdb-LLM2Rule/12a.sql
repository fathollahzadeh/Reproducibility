SELECT MIN("t"."name") AS "movie_company", MIN("t4"."info") AS "rating", MIN("t5"."title") AS "drama_horror_movie"
FROM (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t"
CROSS JOIN (SELECT *
FROM "company_type"
WHERE "kind" = 'production companies') AS "t0"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'genres') AS "t1"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'rating') AS "t2"
INNER JOIN "movie_companies" ON "t0"."id" = "movie_companies"."company_type_id" AND "t"."id" = "movie_companies"."company_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "info" IN ('Drama', 'Horror')) AS "t3" ON "t1"."id" = "t3"."info_type_id" AND "movie_companies"."movie_id" = "t3"."movie_id"
INNER JOIN (SELECT *
FROM "movie_info_idx"
WHERE "info" > '8.0') AS "t4" ON "t2"."id" = "t4"."info_type_id" AND "movie_companies"."movie_id" = "t4"."movie_id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" >= 2005 AND "production_year" <= 2008) AS "t5" ON "t3"."movie_id" = "t5"."id"