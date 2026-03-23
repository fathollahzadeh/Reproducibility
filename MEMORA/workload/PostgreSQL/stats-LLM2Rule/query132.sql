SELECT COALESCE(SUM("$cor0"."$f4" * "t14"."EXPR$0"), 0)
FROM (SELECT "t10"."userid" AS "userid0", "$cor1"."$f4" * "t10"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "$cor3"."userid", "$cor3"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "viewcount" >= 0 AND ("answercount" >= 0 AND "answercount" <= 5)
GROUP BY "owneruserid"
HAVING "$cor3"."userid" = "owneruserid") AS "t2") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 2 AND ("creationdate" >= TIMESTAMP '2010-11-05 01:25:39' AND "creationdate" <= TIMESTAMP '2014-09-09 07:14:12')
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t6") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" >= 0 AND "bountyamount" <= 100 AND CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-26 00:00:00'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t10") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "views" <= 13
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t14"