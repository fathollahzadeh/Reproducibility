SELECT MIN("name"."name") AS "member_in_charnamed_movie"
FROM "name"
INNER JOIN "cast_info" ON "name"."id" = "cast_info"."person_id"