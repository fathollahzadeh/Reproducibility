SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "viewcount" >= 0
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor2"."userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" <= 306 AND "upvotes" >= 0
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t10"