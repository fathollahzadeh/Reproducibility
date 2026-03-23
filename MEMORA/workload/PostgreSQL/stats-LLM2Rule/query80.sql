SELECT COALESCE(SUM("$cor0"."$f4" * "t7"."EXPR$0"), 0)
FROM (SELECT "t3"."owneruserid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-27 17:46:38'
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" >= 0 AND "answercount" <= 4 AND ("commentcount" >= 0 AND "commentcount" <= 11) AND ("creationdate" >= TIMESTAMP '2010-07-26 09:46:48' AND "creationdate" <= TIMESTAMP '2014-09-13 10:09:50')
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor1"."userid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND ("creationdate" >= TIMESTAMP '2010-08-03 19:42:40' AND "creationdate" <= TIMESTAMP '2014-09-12 02:20:03')
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t7"