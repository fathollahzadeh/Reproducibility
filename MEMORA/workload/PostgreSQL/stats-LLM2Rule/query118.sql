SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t12"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t7"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "t3"."id", "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" <= TIMESTAMP '2014-07-28 13:25:35'
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND ("answercount" >= 0 AND "answercount" <= 4)
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t3") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-20 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-03 00:00:00'
GROUP BY "postid"
HAVING "$cor1"."id" = "postid") AS "t7"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" = 0 AND "creationdate" <= TIMESTAMP '2014-08-08 07:03:29'
GROUP BY "id"
HAVING "id" = "$cor0"."owneruserid") AS "t12"