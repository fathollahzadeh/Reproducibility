SELECT COALESCE(SUM("$cor0"."$f4" * "t12"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."EXPR$0" * "t8"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", COALESCE(SUM("$cor2"."EXPR$0" * "t3"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-12 00:00:00'
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND "score" >= -1 AND ("favoritecount" >= 0 AND "favoritecount" <= 20)
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t3"
GROUP BY "t3"."owneruserid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-07-20 19:02:22' AND "date" <= TIMESTAMP '2014-09-03 23:36:09'
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t8") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" <= 2 AND "upvotes" >= 0 AND "creationdate" >= TIMESTAMP '2010-11-26 03:34:11'
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t12"