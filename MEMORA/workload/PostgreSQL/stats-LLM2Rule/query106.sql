SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "t6"."userid" AS "userid0", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" <= TIMESTAMP '2014-08-28 07:25:55'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 2
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "views" >= 0 AND "downvotes" >= 0 AND ("upvotes" >= 0 AND "upvotes" <= 15) AND ("creationdate" >= TIMESTAMP '2010-09-03 11:45:16' AND "creationdate" <= TIMESTAMP '2014-08-18 17:19:53')
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t10"