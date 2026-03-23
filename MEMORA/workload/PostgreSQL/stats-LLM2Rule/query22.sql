SELECT COALESCE(SUM("$cor0"."$f4" * "t6"."EXPR$0"), 0)
FROM (SELECT "t2"."owneruserid", "$cor1"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" >= 0 AND "commentcount" <= 12
GROUP BY "owneruserid"
HAVING "$cor1"."userid" = "owneruserid") AS "t2") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "creationdate" >= TIMESTAMP '2010-07-22 04:38:06' AND "creationdate" <= TIMESTAMP '2014-09-08 15:55:02'
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t6"