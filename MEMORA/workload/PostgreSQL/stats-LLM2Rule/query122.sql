SELECT COALESCE(SUM("$cor0"."$f4" * "t9"."EXPR$0"), 0)
FROM (SELECT "t6"."id", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-07-27 18:08:19' AND "creationdate" <= TIMESTAMP '2014-09-10 08:22:43'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 2
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor2"."userid") AS "t3") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor1"."owneruserid" = "id") AS "t6") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "userid" = "$cor0"."id") AS "t9"