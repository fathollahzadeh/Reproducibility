SELECT MIN("t2"."info") AS "release_date", MIN("t3"."title") AS "youtube_movie"
FROM "aka_title"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]' AND "name" = 'YouTube') AS "t"
CROSS JOIN "company_type"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'release dates') AS "t0"
CROSS JOIN "keyword"
INNER JOIN (SELECT *
FROM "movie_companies"
WHERE "note" LIKE '%(200%)%' AND "note" LIKE '%(worldwide)%') AS "t1" ON "aka_title"."movie_id" = "t1"."movie_id" AND "t"."id" = "t1"."company_id" AND "company_type"."id" = "t1"."company_type_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "note" LIKE '%internet%' AND "info" LIKE 'USA:% 200%') AS "t2" ON "t1"."movie_id" = "t2"."movie_id" AND "t0"."id" = "t2"."info_type_id"
INNER JOIN "movie_keyword" ON "t2"."movie_id" = "movie_keyword"."movie_id" AND "keyword"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" >= 2005 AND "production_year" <= 2010) AS "t3" ON "aka_title"."movie_id" = "t3"."id"