SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t6"."EXPR$0"), 0)
FROM (SELECT "t2"."id", COALESCE(SUM("$cor1"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" <= 18 AND ("creationdate" >= TIMESTAMP '2010-07-23 07:27:31' AND "creationdate" <= TIMESTAMP '2014-09-09 01:43:00')
GROUP BY "id", "owneruserid"
HAVING "$cor1"."userid" = "owneruserid") AS "t2"
GROUP BY "t2"."id") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "postid"
HAVING "$cor0"."id" = "postid") AS "t6"