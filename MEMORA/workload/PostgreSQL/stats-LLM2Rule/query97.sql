SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-27 12:03:40'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= 0 AND "score" <= 28 AND ("viewcount" >= 0 AND "viewcount" <= 6517) AND ("answercount" >= 0 AND "answercount" <= 5) AND ("favoritecount" >= 0 AND "favoritecount" <= 8) AND ("creationdate" >= TIMESTAMP '2010-07-27 11:29:20' AND "creationdate" <= TIMESTAMP '2014-09-13 02:50:15')
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor2"."userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "creationdate" >= TIMESTAMP '2010-07-27 09:38:05'
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t10"