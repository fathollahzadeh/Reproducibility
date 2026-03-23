SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" >= 0 AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-11 00:00:00'
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" <= 57 AND ("creationdate" >= TIMESTAMP '2010-08-26 09:01:31' AND "creationdate" <= TIMESTAMP '2014-08-10 11:01:39')
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t10"