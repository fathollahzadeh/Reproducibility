SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "t6"."userid", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."userid" AS "userid0", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 2
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-08-19 12:45:55' AND "creationdate" <= TIMESTAMP '2014-09-03 21:46:37'
GROUP BY "userid"
HAVING "userid" = "$cor2"."userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."userid0" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 1183 AND "views" >= 0
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t10"