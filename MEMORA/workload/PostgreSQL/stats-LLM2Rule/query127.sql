SELECT COALESCE(SUM("$cor0"."$f4" * "t14"."EXPR$0"), 0)
FROM (SELECT "$cor1"."id0", "$cor1"."$f4" * "t10"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."id" AS "id0", "$cor2"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."id", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "favoritecount" >= 0 AND ("creationdate" >= TIMESTAMP '2010-07-23 02:00:12' AND "creationdate" <= TIMESTAMP '2014-09-08 13:52:41')
GROUP BY "id"
HAVING "id" = "$cor3"."postid") AS "t3") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1 AND "creationdate" >= TIMESTAMP '2011-10-06 21:41:26'
GROUP BY "postid"
HAVING "$cor2"."id" = "postid") AS "t7") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t10") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 2
GROUP BY "postid"
HAVING "$cor0"."id0" = "postid") AS "t14"