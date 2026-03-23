SELECT COALESCE(SUM("$cor0"."$f4" * "t13"."EXPR$0"), 0)
FROM (SELECT "$cor1"."id0", "$cor1"."$f4" * "t9"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."id" AS "id0", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."id", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" <= TIMESTAMP '2014-09-10 02:42:35'
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND "viewcount" <= 5896 AND "answercount" >= 0 AND "creationdate" >= TIMESTAMP '2010-07-29 15:57:21'
GROUP BY "id"
HAVING "id" = "$cor3"."postid") AS "t3") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "postid"
HAVING "$cor2"."id" = "postid") AS "t6") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t9") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 2
GROUP BY "postid"
HAVING "$cor0"."id0" = "postid") AS "t13"