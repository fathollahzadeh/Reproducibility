SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t2"."owneruserid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" <= 52 AND "answercount" >= 0
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor2"."userid") AS "t2") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-20 00:00:00'
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" >= 0 AND ("creationdate" >= TIMESTAMP '2010-10-05 05:52:35' AND "creationdate" <= TIMESTAMP '2014-09-08 15:55:02')
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t10"