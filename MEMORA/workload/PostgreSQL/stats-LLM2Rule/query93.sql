SELECT COALESCE(SUM("$cor0"."$f4" * "t6"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 2 AND "creationdate" <= TIMESTAMP '2014-08-26 22:40:26'
GROUP BY "owneruserid"
HAVING "$cor1"."userid" = "owneruserid") AS "t2") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t6"