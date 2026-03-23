SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "t7"."userid", "$cor1"."EXPR$0" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "t2"."owneruserid", COALESCE(SUM("$cor2"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" >= 0 AND "answercount" <= 7 AND "creationdate" <= TIMESTAMP '2014-09-12 00:03:32'
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t2"
GROUP BY "t2"."owneruserid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-09-11 07:27:36'
GROUP BY "userid"
HAVING "userid" = "$cor1"."owneruserid") AS "t7") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t10"