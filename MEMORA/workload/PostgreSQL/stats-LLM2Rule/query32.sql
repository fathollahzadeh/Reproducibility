SELECT COALESCE(SUM("$cor0"."$f4" * "t11"."EXPR$0"), 0)
FROM (SELECT "t7"."userid", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."userid" AS "userid0", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-08-12 20:33:46' AND "creationdate" <= TIMESTAMP '2014-09-13 19:26:55'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2011-04-11 14:46:09' AND "creationdate" <= TIMESTAMP '2014-08-17 16:37:23'
GROUP BY "userid"
HAVING "userid" = "$cor2"."userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-26 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-12 00:00:00'
GROUP BY "userid"
HAVING "userid" = "$cor1"."userid0") AS "t7") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "views" <= 783 AND ("downvotes" >= 0 AND "downvotes" <= 1) AND "upvotes" <= 123
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t11"