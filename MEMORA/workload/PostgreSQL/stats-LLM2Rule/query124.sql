SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "t6"."id", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-10 00:00:00'
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t2") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" >= 0 AND "downvotes" <= 3 AND ("upvotes" >= 0 AND "upvotes" <= 71)
GROUP BY "id"
HAVING "$cor1"."userid" = "id") AS "t6") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-07-19 21:54:06'
GROUP BY "userid"
HAVING "$cor0"."id" = "userid") AS "t10"