SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0 AND ("creationdate" >= TIMESTAMP '2010-09-05 16:04:35' AND "creationdate" <= TIMESTAMP '2014-09-11 04:35:36')
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 1 AND ("creationdate" >= TIMESTAMP '2010-07-26 20:01:58' AND "creationdate" <= TIMESTAMP '2014-09-13 17:29:23')
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-09-04 08:54:56'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t7") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t10"