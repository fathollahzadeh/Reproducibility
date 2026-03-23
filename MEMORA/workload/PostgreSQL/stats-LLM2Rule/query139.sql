SELECT COALESCE(SUM("$cor0"."$f4" * "t19"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."EXPR$0" * "t15"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."owneruserid", COALESCE(SUM("$cor2"."$f5" * "t10"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."id" AS "id0", "$cor3"."owneruserid", "$cor3"."$f5" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "t2"."id", "t2"."owneruserid", "$cor4"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor4",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND "score" <= 14
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor4"."postid") AS "t2") AS "$cor3",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" <= TIMESTAMP '2014-06-25 13:05:06'
GROUP BY "relatedpostid"
HAVING "$cor3"."id" = "relatedpostid") AS "t6") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2009-02-02 00:00:00'
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t10"
GROUP BY "$cor2"."owneruserid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-08-04 08:50:31' AND "date" <= TIMESTAMP '2014-09-02 02:51:22'
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t15") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" >= 0
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t19"