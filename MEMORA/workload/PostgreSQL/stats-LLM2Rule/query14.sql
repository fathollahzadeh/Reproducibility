SELECT COALESCE(SUM("$cor0"."$f4" * "t7"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-10-01 20:45:26' AND "creationdate" <= TIMESTAMP '2014-09-05 12:51:17'
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" <= 100
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" = 0 AND "creationdate" <= TIMESTAMP '2014-09-12 03:25:34'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t7"