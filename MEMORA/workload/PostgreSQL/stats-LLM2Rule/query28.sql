SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."EXPR$0" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t2"."owneruserid", COALESCE(SUM("$cor2"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" <= 22
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t2"
GROUP BY "t2"."owneruserid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t10"