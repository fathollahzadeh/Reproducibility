SELECT COALESCE(SUM("$cor0"."$f4" * "t12"."EXPR$0"), 0)
FROM (SELECT "$cor1"."postid0", "$cor1"."$f4" * "t9"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."postid0", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."postid" AS "postid0", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" >= TIMESTAMP '2011-03-22 06:18:34' AND "creationdate" <= TIMESTAMP '2014-08-22 20:04:25'
GROUP BY "postid"
HAVING "postid" = "$cor3"."postid") AS "t3") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor2"."postid0" = "postid") AS "t6") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor1"."postid0" = "postid") AS "t9") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
GROUP BY "id"
HAVING "$cor0"."postid0" = "id") AS "t12"