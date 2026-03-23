SELECT COALESCE(SUM("$cor0"."$f4" * "t13"."EXPR$0"), 0)
FROM (SELECT "$cor1"."postid0", "$cor1"."$f4" * "t10"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."postid0", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t2"."postid" AS "postid0", "$cor3"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1 AND "creationdate" >= TIMESTAMP '2010-10-19 15:02:42'
GROUP BY "postid"
HAVING "postid" = "$cor3"."postid") AS "t2") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" <= TIMESTAMP '2014-06-18 17:14:07'
GROUP BY "postid"
HAVING "$cor2"."postid0" = "postid") AS "t6") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-20 00:00:00'
GROUP BY "postid"
HAVING "$cor1"."postid0" = "postid") AS "t10") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
GROUP BY "id"
HAVING "$cor0"."postid0" = "id") AS "t13"