SELECT MIN("t2"."name") AS "voicing_actress", MIN("t4"."title") AS "jap_engl_voiced_movie"
FROM "aka_name"
CROSS JOIN "char_name"
INNER JOIN (SELECT *
FROM "cast_info"
WHERE "note" IN ('(voice)', '(voice) (uncredited)', '(voice: English version)', '(voice: Japanese version)')) AS "t" ON "aka_name"."person_id" = "t"."person_id" AND "char_name"."id" = "t"."person_role_id"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t0"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'release dates') AS "t1"
INNER JOIN "movie_companies" ON "t"."movie_id" = "movie_companies"."movie_id" AND "t0"."id" = "movie_companies"."company_id"
INNER JOIN "movie_info" ON "movie_companies"."movie_id" = "movie_info"."movie_id" AND "t1"."id" = "movie_info"."info_type_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "gender" = 'f') AS "t2" ON "t"."person_id" = "t2"."id"
INNER JOIN (SELECT *
FROM "role_type"
WHERE "role" = 'actress') AS "t3" ON "t"."role_id" = "t3"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" > 2000) AS "t4" ON "movie_info"."movie_id" = "t4"."id"