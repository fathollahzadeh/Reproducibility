SELECT MIN("char_name"."name") AS "uncredited_voiced_character", MIN("t2"."title") AS "russian_movie"
FROM "char_name"
INNER JOIN (SELECT *
FROM "cast_info"
WHERE "note" LIKE '%(voice)%' AND "note" LIKE '%(uncredited)%') AS "t" ON "char_name"."id" = "t"."person_role_id"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[ru]') AS "t0"
CROSS JOIN "company_type"
INNER JOIN "movie_companies" ON "t"."movie_id" = "movie_companies"."movie_id" AND "t0"."id" = "movie_companies"."company_id" AND "company_type"."id" = "movie_companies"."company_type_id"
INNER JOIN (SELECT *
FROM "role_type"
WHERE "role" = 'actor') AS "t1" ON "t"."role_id" = "t1"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2005) AS "t2" ON "movie_companies"."movie_id" = "t2"."id"