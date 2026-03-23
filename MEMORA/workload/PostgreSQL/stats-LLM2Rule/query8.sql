SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t8"."EXPR$0"), 0)
FROM (SELECT "t3"."id", COALESCE(SUM("$cor1"."EXPR$0" * "t3"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "creationdate" >= TIMESTAMP '2010-09-06 00:58:21' AND "creationdate" <= TIMESTAMP '2014-09-12 10:02:21'
GROUP BY "id", "owneruserid"
HAVING "$cor1"."userid" = "owneruserid") AS "t3"
GROUP BY "t3"."id") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1 AND "creationdate" >= TIMESTAMP '2011-07-09 22:35:44'
GROUP BY "postid"
HAVING "$cor0"."id" = "postid") AS "t8"