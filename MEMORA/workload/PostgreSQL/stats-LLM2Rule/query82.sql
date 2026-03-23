SELECT COALESCE(SUM("$cor0"."$f4" * "t6"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-08-09 07:24:50' AND "creationdate" <= TIMESTAMP '2014-09-10 03:46:02'
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t2") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "views" <= 80 AND "upvotes" >= 0 AND "creationdate" >= TIMESTAMP '2010-08-02 20:31:12'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t6"