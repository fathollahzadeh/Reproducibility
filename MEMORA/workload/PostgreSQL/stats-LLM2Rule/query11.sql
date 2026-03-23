SELECT COALESCE(SUM("$cor0"."$f4" * "t7"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= 0 AND "score" <= 15 AND ("viewcount" >= 0 AND "viewcount" <= 3002) AND "answercount" <= 3 AND "commentcount" <= 10
GROUP BY "owneruserid"
HAVING "$cor1"."userid" = "owneruserid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" <= 0 AND "upvotes" >= 0 AND ("creationdate" >= TIMESTAMP '2010-08-23 16:21:10' AND "creationdate" <= TIMESTAMP '2014-09-02 09:50:06')
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t7"