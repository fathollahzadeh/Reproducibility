SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t7"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" <= 17
GROUP BY "id", "owneruserid") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "postid"
HAVING "$cor1"."id" = "postid") AS "t2"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "creationdate" <= TIMESTAMP '2014-09-12 07:12:16'
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t7"