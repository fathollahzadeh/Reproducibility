SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t12"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t7"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "t3"."id", "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-07-21 00:44:08'
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "viewcount" >= 0 AND "commentcount" >= 0
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t3") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 2
GROUP BY "postid"
HAVING "$cor1"."id" = "postid") AS "t7"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "views" <= 34 AND "upvotes" >= 0
GROUP BY "id"
HAVING "id" = "$cor0"."owneruserid") AS "t12"