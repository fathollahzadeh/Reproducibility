SELECT COALESCE(SUM("$cor0"."$f4" * "t6"."EXPR$0"), 0)
FROM (SELECT "t2"."postid", "$cor1"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "creationdate" >= TIMESTAMP '2010-07-19 20:08:37'
GROUP BY "id") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "postid"
HAVING "$cor1"."id" = "postid") AS "t2") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-07-20 00:30:00'
GROUP BY "postid"
HAVING "$cor0"."postid" = "postid") AS "t6"