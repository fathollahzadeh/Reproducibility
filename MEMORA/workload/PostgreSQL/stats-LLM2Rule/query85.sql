SELECT COALESCE(SUM("$cor0"."$f4" * "t6"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-11 00:00:00'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t2") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "creationdate" >= TIMESTAMP '2010-07-19 20:11:48' AND "creationdate" <= TIMESTAMP '2014-07-09 20:37:10'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t6"