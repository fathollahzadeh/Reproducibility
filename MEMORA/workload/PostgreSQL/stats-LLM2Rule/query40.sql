SELECT COALESCE(SUM("$cor0"."$f4" * "t11"."EXPR$0"), 0)
FROM (SELECT "t8"."id", "$cor1"."EXPR$0" * "t8"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", COALESCE(SUM("$cor2"."EXPR$0" * "t3"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1
GROUP BY "relatedpostid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND "commentcount" <= 8 AND ("creationdate" >= TIMESTAMP '2010-07-21 12:30:43' AND "creationdate" <= TIMESTAMP '2014-09-07 01:11:03')
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."relatedpostid") AS "t3"
GROUP BY "t3"."owneruserid") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" <= 40 AND ("creationdate" >= TIMESTAMP '2010-07-26 19:11:25' AND "creationdate" <= TIMESTAMP '2014-09-11 22:26:42')
GROUP BY "id"
HAVING "id" = "$cor1"."owneruserid") AS "t8") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor0"."id" = "userid") AS "t11"