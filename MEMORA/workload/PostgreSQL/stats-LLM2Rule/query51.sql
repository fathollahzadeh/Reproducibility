SELECT COALESCE(SUM("$cor0"."$f4" * "t15"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t11"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "$cor3"."userid", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-31 05:18:59' AND "creationdate" <= TIMESTAMP '2014-09-12 07:59:13'
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -2 AND ("viewcount" >= 0 AND "viewcount" <= 18281)
GROUP BY "owneruserid"
HAVING "$cor3"."userid" = "owneruserid") AS "t3") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 2
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t7") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-10-20 08:33:44'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t11") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "views" <= 75
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t15"