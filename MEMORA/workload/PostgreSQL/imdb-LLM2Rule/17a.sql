SELECT MIN("t"."name") AS "member_in_charnamed_american_movie", MIN("t"."name") AS "a1"
FROM (SELECT *
FROM "name"
WHERE "name" LIKE 'B%') AS "t"
INNER JOIN "cast_info" ON "t"."id" = "cast_info"."person_id"