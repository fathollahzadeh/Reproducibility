SELECT COALESCE(SUM("$cor0"."$f4" * "t12"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid" AS "userid0", "$cor1"."$f4" * "t9"."EXPR$0" AS "$f4"
FROM (SELECT "t6"."userid", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND ("viewcount" >= 0 AND "viewcount" <= 4157) AND "favoritecount" = 0 AND "creationdate" <= TIMESTAMP '2014-09-08 09:58:16'
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor3"."userid") AS "t3") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "$cor2"."owneruserid" = "userid") AS "t6") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t9") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t12"