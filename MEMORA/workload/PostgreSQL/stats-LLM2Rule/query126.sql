SELECT COALESCE(SUM("$cor0"."$f4" * "t8"."EXPR$0"), 0)
FROM (SELECT "t5"."id", "$cor1"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t1"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t1") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0
GROUP BY "id"
HAVING "$cor1"."userid" = "id") AS "t5") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor0"."id" = "userid") AS "t8"