SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t7"."EXPR$0"), 0)
FROM (SELECT "t2"."owneruserid", COALESCE(SUM("$cor1"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid") AS "$cor1",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "creationdate" >= TIMESTAMP '2010-08-17 19:08:05' AND "creationdate" <= TIMESTAMP '2014-08-31 06:58:12'
GROUP BY "id", "owneruserid"
HAVING "$cor1"."postid" = "id") AS "t2"
GROUP BY "t2"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" >= 0 AND "upvotes" <= 9
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t7"