SELECT COALESCE(SUM("$cor0"."$f4" * "t7"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-07-19 20:54:06'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" >= 0 AND ("upvotes" >= 0 AND "upvotes" <= 17) AND ("creationdate" >= TIMESTAMP '2010-08-06 07:03:05' AND "creationdate" <= TIMESTAMP '2014-09-08 04:18:44')
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t7"