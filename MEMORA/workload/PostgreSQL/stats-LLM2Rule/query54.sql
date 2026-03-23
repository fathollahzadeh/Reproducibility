SELECT COALESCE(SUM("$cor0"."$f4" * "t14"."EXPR$0"), 0)
FROM (SELECT "t11"."id", "$cor1"."EXPR$0" * "t11"."EXPR$0" AS "$f4"
FROM (SELECT "t6"."owneruserid", COALESCE(SUM("$cor2"."$f4" * "t6"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "t2"."relatedpostid", "$cor3"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1 AND "creationdate" >= TIMESTAMP '2011-04-12 15:23:59'
GROUP BY "relatedpostid"
HAVING "relatedpostid" = "$cor3"."postid") AS "t2") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" = 1 AND "viewcount" >= 0 AND "favoritecount" >= 0
GROUP BY "id", "owneruserid"
HAVING "$cor2"."relatedpostid" = "id") AS "t6"
GROUP BY "t6"."owneruserid") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "creationdate" >= TIMESTAMP '2011-02-08 18:11:37'
GROUP BY "id"
HAVING "id" = "$cor1"."owneruserid") AS "t11") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor0"."id" = "userid") AS "t14"