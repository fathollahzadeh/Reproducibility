SELECT MIN("char_name"."name") AS "character1", MIN("t1"."title") AS "movie_with_american_producer"
FROM "char_name"
INNER JOIN (SELECT *
FROM "cast_info"
WHERE "note" LIKE '%(producer)%') AS "t" ON "char_name"."id" = "t"."person_role_id"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t0"
CROSS JOIN "company_type"
INNER JOIN "movie_companies" ON "t"."movie_id" = "movie_companies"."movie_id" AND "t0"."id" = "movie_companies"."company_id" AND "company_type"."id" = "movie_companies"."company_type_id"
INNER JOIN "role_type" ON "t"."role_id" = "role_type"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 1990) AS "t1" ON "movie_companies"."movie_id" = "t1"."id"