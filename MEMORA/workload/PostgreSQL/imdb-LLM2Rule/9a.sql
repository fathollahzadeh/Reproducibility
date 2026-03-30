SELECT MIN("aka_name"."name") AS "alternative_name", MIN("char_name"."name") AS "character_name", MIN("t4"."title") AS "movie"
FROM "aka_name"
CROSS JOIN "char_name"
INNER JOIN (SELECT *
FROM "cast_info"
WHERE "note" IN ('(voice)', '(voice) (uncredited)', '(voice: English version)', '(voice: Japanese version)')) AS "t" ON "char_name"."id" = "t"."person_role_id" AND "aka_name"."person_id" = "t"."person_id"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t0"
INNER JOIN (SELECT *
FROM "movie_companies"
WHERE "note" LIKE '%(USA)%' OR "note" LIKE '%(worldwide)%') AS "t1" ON "t"."movie_id" = "t1"."movie_id" AND "t0"."id" = "t1"."company_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "gender" = 'f' AND "name" LIKE '%Ang%') AS "t2" ON "t"."person_id" = "t2"."id"
INNER JOIN (SELECT *
FROM "role_type"
WHERE "role" = 'actress') AS "t3" ON "t"."role_id" = "t3"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" >= 2005 AND "production_year" <= 2015) AS "t4" ON "t"."movie_id" = "t4"."id"