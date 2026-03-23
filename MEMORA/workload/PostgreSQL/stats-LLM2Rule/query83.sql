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
WHERE "reputation" >= 1 AND "reputation" <= 7931 AND "views" <= 109 AND "downvotes" >= 0 AND "creationdate" <= TIMESTAMP '2014-09-12 13:12:56'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t5"