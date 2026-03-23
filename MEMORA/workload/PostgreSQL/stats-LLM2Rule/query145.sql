SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t19"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t14"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor2"."id0", "$cor2"."owneruserid", "$cor2"."$f5" * "t10"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."id" AS "id0", "$cor3"."owneruserid", "$cor3"."$f5" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "t2"."id", "t2"."owneruserid", "$cor4"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor4",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND "answercount" >= 0 AND ("creationdate" >= TIMESTAMP '2010-07-21 15:23:53' AND "creationdate" <= TIMESTAMP '2014-09-11 23:26:14')
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor4"."postid") AS "t2") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" >= TIMESTAMP '2010-11-16 01:27:37' AND "creationdate" <= TIMESTAMP '2014-08-21 15:25:23'
GROUP BY "postid"
HAVING "$cor3"."id" = "postid") AS "t6") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 5
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t10") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-21 00:00:00'
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t14"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" >= 0 AND "creationdate" <= TIMESTAMP '2014-09-11 20:31:48'
GROUP BY "id"
HAVING "id" = "$cor0"."owneruserid") AS "t19"