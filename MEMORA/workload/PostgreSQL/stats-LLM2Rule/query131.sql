SELECT COALESCE(SUM("$cor0"."$f4" * "t15"."EXPR$0"), 0)
FROM (SELECT "t11"."userid" AS "userid0", "$cor1"."$f4" * "t11"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "$cor3"."userid", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 2
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" >= 0 AND "answercount" <= 9 AND ("creationdate" >= TIMESTAMP '2010-07-20 18:17:25' AND "creationdate" <= TIMESTAMP '2014-08-26 12:57:22')
GROUP BY "owneruserid"
HAVING "$cor3"."userid" = "owneruserid") AS "t3") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" <= TIMESTAMP '2014-09-02 07:58:47'
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t7") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" >= 0 AND CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-05-19 00:00:00'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t11") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" <= 230 AND ("creationdate" >= TIMESTAMP '2010-09-22 01:07:10' AND "creationdate" <= TIMESTAMP '2014-08-15 05:52:23')
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t15"