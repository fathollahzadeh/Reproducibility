SELECT COALESCE(SUM("$cor0"."$f4" * "t15"."EXPR$0"), 0)
FROM (SELECT "$cor1"."id0", "$cor1"."$f4" * "t11"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."id" AS "id0", "$cor2"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."id", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-08-01 12:12:41'
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" <= 44 AND ("favoritecount" >= 0 AND "favoritecount" <= 3) AND ("creationdate" >= TIMESTAMP '2010-08-11 13:53:56' AND "creationdate" <= TIMESTAMP '2014-09-03 11:52:36')
GROUP BY "id"
HAVING "id" = "$cor3"."postid") AS "t3") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1 AND "creationdate" <= TIMESTAMP '2014-08-11 17:26:31'
GROUP BY "postid"
HAVING "$cor2"."id" = "postid") AS "t7") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-09-20 19:11:45'
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t11") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-11 00:00:00'
GROUP BY "postid"
HAVING "$cor0"."id0" = "postid") AS "t15"