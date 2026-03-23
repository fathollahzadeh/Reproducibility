SELECT COALESCE(SUM("$cor0"."$f4" * "t12"."EXPR$0"), 0)
FROM (SELECT "$cor1"."id" AS "id1", "$cor1"."$f4" * "t9"."EXPR$0" AS "$f4"
FROM (SELECT "t6"."id", "$cor2"."EXPR$0" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t1"."owneruserid", COALESCE(SUM("$cor3"."EXPR$0" * "t1"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "excerptpostid", COUNT(*) AS "EXPR$0"
FROM "tags"
GROUP BY "excerptpostid") AS "$cor3",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor3"."excerptpostid") AS "t1"
GROUP BY "t1"."owneruserid") AS "$cor2",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" >= 0
GROUP BY "id"
HAVING "id" = "$cor2"."owneruserid") AS "t6") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor1"."id" = "userid") AS "t9") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor0"."id1" = "userid") AS "t12"