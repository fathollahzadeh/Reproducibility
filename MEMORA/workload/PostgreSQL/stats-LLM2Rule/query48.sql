SELECT COALESCE(SUM("$cor0"."$f5" * "t13"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid" AS "userid1", "$cor1"."$f4" * "t9"."EXPR$0" AS "$f5"
FROM (SELECT "$cor2"."userid0", "t6"."userid", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."userid" AS "userid0", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-20 21:37:31'
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 12
GROUP BY "userid"
HAVING "userid" = "$cor3"."userid") AS "t3") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "userid" = "$cor2"."userid0") AS "t6") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor1"."userid0" = "userid") AS "t9") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" = 0
GROUP BY "id"
HAVING "id" = "$cor0"."userid1") AS "t13"