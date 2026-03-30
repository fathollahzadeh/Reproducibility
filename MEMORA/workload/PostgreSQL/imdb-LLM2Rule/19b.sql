SELECT MIN("t4"."name") AS "voicing_actress", MIN("t6"."title") AS "kung_fu_panda"
FROM "aka_name"
CROSS JOIN "char_name"
INNER JOIN (SELECT *
FROM "cast_info"
WHERE "note" = '(voice)') AS "t" ON "aka_name"."person_id" = "t"."person_id" AND "char_name"."id" = "t"."person_role_id"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t0"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'release dates') AS "t1"
INNER JOIN (SELECT *
FROM "movie_companies"
WHERE "note" LIKE '%(200%)%' AND ("note" LIKE '%(USA)%' OR "note" LIKE '%(worldwide)%')) AS "t2" ON "t"."movie_id" = "t2"."movie_id" AND "t0"."id" = "t2"."company_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "info" LIKE 'Japan:%2007%' OR "info" LIKE 'USA:%2008%') AS "t3" ON "t2"."movie_id" = "t3"."movie_id" AND "t1"."id" = "t3"."info_type_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "gender" = 'f' AND "name" LIKE '%Angel%') AS "t4" ON "t"."person_id" = "t4"."id"
INNER JOIN (SELECT *
FROM "role_type"
WHERE "role" = 'actress') AS "t5" ON "t"."role_id" = "t5"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" >= 2007 AND "production_year" <= 2008 AND "title" LIKE '%Kung%Fu%Panda%') AS "t6" ON "t3"."movie_id" = "t6"."id"