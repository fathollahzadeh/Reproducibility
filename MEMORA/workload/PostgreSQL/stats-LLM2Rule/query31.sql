SELECT COALESCE(SUM("$cor0"."$f4" * "t11"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-06 00:00:00'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" <= 48 AND "answercount" <= 8
GROUP BY "owneruserid"
HAVING "$cor2"."userid" = "owneruserid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2011-01-03 20:50:19' AND "date" <= TIMESTAMP '2014-09-02 15:35:07'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t7") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "creationdate" >= TIMESTAMP '2010-11-16 06:03:04'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t11"