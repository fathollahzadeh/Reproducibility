SELECT COALESCE(SUM("$cor0"."$f4" * "t13"."EXPR$0"), 0)
FROM (SELECT "$cor1"."postid0", "$cor1"."$f4" * "t10"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."postid0", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."postid" AS "postid0", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" >= TIMESTAMP '2011-11-21 22:39:41' AND "creationdate" <= TIMESTAMP '2014-09-01 16:29:56'
GROUP BY "postid"
HAVING "postid" = "$cor3"."postid") AS "t3") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor2"."postid0" = "postid") AS "t6") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-22 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-14 00:00:00'
GROUP BY "postid"
HAVING "$cor1"."postid0" = "postid") AS "t10") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
GROUP BY "id"
HAVING "$cor0"."postid0" = "id") AS "t13"