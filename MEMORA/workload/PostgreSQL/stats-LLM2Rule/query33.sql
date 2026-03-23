SELECT COALESCE(SUM("$cor0"."$f4" * "t9"."EXPR$0"), 0)
FROM (SELECT "t5"."userid", "$cor1"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "t1"."userid" AS "userid0", "$cor2"."EXPR$0" * "t1"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "userid" = "$cor2"."userid") AS "t1") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" >= 0 AND (CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-26 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-08 00:00:00')
GROUP BY "userid"
HAVING "userid" = "$cor1"."userid0") AS "t5") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND ("views" >= 0 AND "views" <= 110) AND "upvotes" = 0 AND ("creationdate" >= TIMESTAMP '2010-07-28 19:29:11' AND "creationdate" <= TIMESTAMP '2014-08-14 05:29:30')
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t9"