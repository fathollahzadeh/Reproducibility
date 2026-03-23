SELECT COALESCE(SUM("$cor0"."$f4" * "t8"."EXPR$0"), 0)
FROM (SELECT "t5"."postid" AS "postid0", "$cor1"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."postid", "$cor2"."EXPR$0" * "t1"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "postid"
HAVING "postid" = "$cor2"."postid") AS "t1") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2011-05-07 21:47:19' AND "creationdate" <= TIMESTAMP '2014-09-10 13:19:54'
GROUP BY "postid"
HAVING "$cor1"."postid" = "postid") AS "t5") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor0"."postid0" = "postid") AS "t8"