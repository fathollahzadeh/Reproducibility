SELECT MIN("t3"."kind") AS "movie_kind", MIN("t5"."title") AS "complete_nerdy_internet_movie"
FROM "complete_cast"
INNER JOIN (SELECT *
FROM "comp_cast_type"
WHERE "kind" = 'complete+verified') AS "t" ON "complete_cast"."status_id" = "t"."id"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t0"
CROSS JOIN "company_type"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'release dates') AS "t1"
CROSS JOIN (SELECT *
FROM "keyword"
WHERE "keyword" IN ('alienation', 'dignity', 'loner', 'nerd')) AS "t2"
CROSS JOIN (SELECT *
FROM "kind_type"
WHERE "kind" = 'movie') AS "t3"
INNER JOIN "movie_companies" ON "complete_cast"."movie_id" = "movie_companies"."movie_id" AND "t0"."id" = "movie_companies"."company_id" AND "company_type"."id" = "movie_companies"."company_type_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "note" LIKE '%internet%' AND "info" LIKE 'USA:% 200%') AS "t4" ON "movie_companies"."movie_id" = "t4"."movie_id" AND "t1"."id" = "t4"."info_type_id"
INNER JOIN "movie_keyword" ON "t4"."movie_id" = "movie_keyword"."movie_id" AND "t2"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2000) AS "t5" ON "t3"."id" = "t5"."kind_id" AND "t4"."movie_id" = "t5"."id"