SELECT COALESCE(SUM("$cor0"."$f4" * "t7"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-27 15:46:34' AND "creationdate" <= TIMESTAMP '2014-09-12 08:15:14'
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-19 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-10 00:00:00'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "creationdate" <= TIMESTAMP '2014-09-03 01:06:41'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t7"