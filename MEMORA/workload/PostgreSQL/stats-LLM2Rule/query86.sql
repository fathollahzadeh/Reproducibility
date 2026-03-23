SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."postid", COALESCE(SUM("$cor1"."$f5" * "t6"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor2"."userid", "$cor2"."postid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid", "postid") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor2"."postid" = "postid") AS "t2") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "views" <= 74
GROUP BY "id"
HAVING "id" = "$cor1"."userid") AS "t6"
GROUP BY "$cor1"."postid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
GROUP BY "id"
HAVING "$cor0"."postid" = "id") AS "t10"