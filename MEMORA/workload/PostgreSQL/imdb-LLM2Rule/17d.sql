SELECT MIN("t"."name") AS "member_in_charnamed_movie"
FROM (SELECT *
FROM "name"
WHERE "name" LIKE '%Bert%') AS "t"
INNER JOIN "cast_info" ON "t"."id" = "cast_info"."person_id"