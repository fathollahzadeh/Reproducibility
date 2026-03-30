SELECT MIN("char_name"."name") AS "voiced_char", MIN("t7"."name") AS "voicing_actress", MIN("t9"."title") AS "voiced_animation"
FROM "aka_name"
CROSS JOIN "complete_cast"
INNER JOIN (SELECT *
FROM "comp_cast_type"
WHERE "kind" = 'cast') AS "t" ON "complete_cast"."subject_id" = "t"."id"
INNER JOIN (SELECT *
FROM "comp_cast_type"
WHERE "kind" = 'complete+verified') AS "t0" ON "complete_cast"."status_id" = "t0"."id"
CROSS JOIN "char_name"
INNER JOIN (SELECT *
FROM "cast_info"
WHERE "note" IN ('(voice)', '(voice) (uncredited)', '(voice: English version)', '(voice: Japanese version)')) AS "t1" ON "complete_cast"."movie_id" = "t1"."movie_id" AND "aka_name"."person_id" = "t1"."person_id" AND "char_name"."id" = "t1"."person_role_id"
CROSS JOIN (SELECT *
FROM "company_name"
WHERE "country_code" = '[us]') AS "t2"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'release dates') AS "t3"
CROSS JOIN (SELECT *
FROM "info_type"
WHERE "info" = 'trivia') AS "t4"
CROSS JOIN (SELECT *
FROM "keyword"
WHERE "keyword" = 'computer-animation') AS "t5"
INNER JOIN "movie_companies" ON "t1"."movie_id" = "movie_companies"."movie_id" AND "t2"."id" = "movie_companies"."company_id"
INNER JOIN (SELECT *
FROM "movie_info"
WHERE "info" LIKE 'Japan:%200%' OR "info" LIKE 'USA:%200%') AS "t6" ON "movie_companies"."movie_id" = "t6"."movie_id" AND "t3"."id" = "t6"."info_type_id"
INNER JOIN "movie_keyword" ON "movie_companies"."movie_id" = "movie_keyword"."movie_id" AND "t5"."id" = "movie_keyword"."keyword_id"
INNER JOIN (SELECT *
FROM "name"
WHERE "gender" = 'f' AND "name" LIKE '%An%') AS "t7" ON "t1"."person_id" = "t7"."id"
INNER JOIN "person_info" ON "t7"."id" = "person_info"."person_id" AND "t4"."id" = "person_info"."info_type_id"
INNER JOIN (SELECT *
FROM "role_type"
WHERE "role" = 'actress') AS "t8" ON "t1"."role_id" = "t8"."id"
INNER JOIN (SELECT *
FROM "title"
WHERE "production_year" >= 2000 AND "production_year" <= 2010) AS "t9" ON "t6"."movie_id" = "t9"."id"