SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t5"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "t2"."id", "t2"."owneruserid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= 0 AND "score" <= 16 AND "viewcount" >= 0 AND "creationdate" <= TIMESTAMP '2014-09-09 12:00:50'
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t2") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor1"."id" = "postid") AS "t5"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND ("creationdate" >= TIMESTAMP '2010-07-19 19:08:49' AND "creationdate" <= TIMESTAMP '2014-08-28 12:15:56')
GROUP BY "id"
HAVING "id" = "$cor0"."owneruserid") AS "t10"