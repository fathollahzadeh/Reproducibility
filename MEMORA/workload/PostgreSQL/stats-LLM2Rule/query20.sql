SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t8"."EXPR$0"), 0)
FROM (SELECT "t3"."owneruserid", COALESCE(SUM("$cor1"."EXPR$0" * "t3"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" <= TIMESTAMP '2014-08-17 21:24:11'
GROUP BY "postid") AS "$cor1",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "creationdate" >= TIMESTAMP '2010-07-26 19:26:37' AND "creationdate" <= TIMESTAMP '2014-08-22 14:43:39'
GROUP BY "id", "owneruserid"
HAVING "$cor1"."postid" = "id") AS "t3"
GROUP BY "t3"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 6524 AND "views" >= 0
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t8"