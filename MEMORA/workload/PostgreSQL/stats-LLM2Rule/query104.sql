SELECT COALESCE(SUM("$cor0"."$f4" * "t9"."EXPR$0"), 0)
FROM (SELECT "t5"."userid" AS "userid0", "$cor1"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-07-28 09:11:34' AND "creationdate" <= TIMESTAMP '2014-09-06 06:51:53'
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t2") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t5") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" <= 0 AND ("upvotes" >= 0 AND "upvotes" <= 72)
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t9"