SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0 AND "creationdate" >= TIMESTAMP '2010-07-20 10:52:57'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 5 AND "creationdate" >= TIMESTAMP '2011-01-31 15:35:37'
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 356 AND "downvotes" <= 34 AND ("creationdate" >= TIMESTAMP '2010-07-19 21:29:29' AND "creationdate" <= TIMESTAMP '2014-08-20 14:31:46')
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t10"