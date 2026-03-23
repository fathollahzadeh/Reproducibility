SELECT COALESCE(SUM("$cor0"."$f4" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."postid0", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."postid" AS "postid0", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0 AND "creationdate" >= TIMESTAMP '2010-08-26 06:55:11'
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" <= TIMESTAMP '2014-09-05 06:39:25'
GROUP BY "postid"
HAVING "postid" = "$cor2"."postid") AS "t3") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 2
GROUP BY "postid"
HAVING "$cor1"."postid0" = "postid") AS "t7") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
GROUP BY "id"
HAVING "$cor0"."postid0" = "id") AS "t10"