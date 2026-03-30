SELECT MIN("aka_title"."title") AS "aka_title", MIN("t2"."title") AS "internet_movie_title"
FROM "aka_title"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t"
CROSS JOIN "company_type"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'release dates') AS "t0"
CROSS JOIN "keyword"
INNER JOIN "movie_companies" ON "aka_title"."movie_id" = "movie_companies"."movie_id" AND "t"."id" = "movie_companies"."company_id" AND "company_type"."id" = "movie_companies"."company_type_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "note" LIKE '%internet%') AS "t1" ON "movie_companies"."movie_id" = "t1"."movie_id" AND "t0"."id" = "t1"."info_type_id"
INNER JOIN "movie_keyword" ON "t1"."movie_id" = "movie_keyword"."movie_id" AND "keyword"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 1990) AS "t2" ON "aka_title"."movie_id" = "t2"."id"