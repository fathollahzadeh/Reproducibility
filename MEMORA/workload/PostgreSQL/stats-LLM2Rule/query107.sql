SELECT COALESCE(SUM("$cor0"."$f4" * "t11"."EXPR$0"), 0)
FROM (SELECT "t7"."userid" AS "userid0", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 1 AND "creationdate" >= TIMESTAMP '2010-08-27 14:12:07'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 5 AND (CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-19 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-13 00:00:00')
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-08-19 10:32:13'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t7") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t11"