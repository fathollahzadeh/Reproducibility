SELECT COALESCE(SUM("$cor0"."$f4" * "t5"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t1"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t1") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 487 AND "upvotes" <= 27 AND ("creationdate" >= TIMESTAMP '2010-10-22 22:40:35' AND "creationdate" <= TIMESTAMP '2014-09-10 17:01:31')
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t5"