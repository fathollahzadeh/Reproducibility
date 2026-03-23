SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "t6"."userid", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t2"."userid" AS "userid0", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" <= TIMESTAMP '2014-08-28 00:18:24'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "userid" = "$cor2"."userid") AS "t2") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-09-15 02:50:48'
GROUP BY "userid"
HAVING "$cor1"."userid0" = "userid") AS "t6") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 1443 AND ("downvotes" >= 0 AND "downvotes" <= 3)
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t10"