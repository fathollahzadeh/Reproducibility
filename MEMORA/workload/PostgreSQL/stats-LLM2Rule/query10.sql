SELECT COALESCE(SUM("$cor0"."$f4" * "t6"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-08-05 00:36:02' AND "creationdate" <= TIMESTAMP '2014-09-08 16:50:49'
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "viewcount" >= 0 AND "viewcount" <= 2897 AND ("commentcount" >= 0 AND "commentcount" <= 16) AND ("favoritecount" >= 0 AND "favoritecount" <= 10)
GROUP BY "owneruserid"
HAVING "$cor1"."userid" = "owneruserid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t6"