SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "t6"."postid" AS "postid0", "$cor1"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."postid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-08-02 23:52:10'
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -3
GROUP BY "id"
HAVING "id" = "$cor2"."postid") AS "t3") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "postid"
HAVING "$cor1"."postid" = "postid") AS "t6") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 2 AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-12 00:00:00'
GROUP BY "postid"
HAVING "$cor0"."postid0" = "postid") AS "t10"