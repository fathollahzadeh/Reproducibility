SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t12"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t7"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "t3"."id", "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0 AND "creationdate" <= TIMESTAMP '2014-09-10 02:47:53'
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= 0 AND "score" <= 19 AND "commentcount" <= 10 AND "creationdate" <= TIMESTAMP '2014-08-28 13:31:33'
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t3") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-12 00:00:00'
GROUP BY "postid"
HAVING "$cor1"."id" = "postid") AS "t7"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" >= 0
GROUP BY "id"
HAVING "id" = "$cor0"."owneruserid") AS "t12"