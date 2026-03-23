SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t5"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "t2"."id", "t2"."owneruserid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-21 11:05:37' AND "creationdate" <= TIMESTAMP '2014-08-25 17:59:25'
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t2") AS "$cor1",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "relatedpostid"
HAVING "$cor1"."id" = "relatedpostid") AS "t5"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" >= 0 AND "creationdate" >= TIMESTAMP '2010-08-21 21:27:38'
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t10"