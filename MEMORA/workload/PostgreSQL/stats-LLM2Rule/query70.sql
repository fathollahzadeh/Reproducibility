SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t18"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", COALESCE(SUM("$cor1"."$f5" * "t13"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor2"."userid", "$cor2"."id0", "$cor2"."$f5" * "t9"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."userid", "$cor3"."id" AS "id0", "$cor3"."$f5" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "t3"."id", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-26 20:21:15' AND "creationdate" <= TIMESTAMP '2014-09-13 18:12:10'
GROUP BY "userid", "postid") AS "$cor4",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" <= 61 AND "viewcount" <= 3627 AND ("answercount" >= 0 AND "answercount" <= 5) AND "commentcount" <= 8 AND "favoritecount" >= 0
GROUP BY "id"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "relatedpostid"
HAVING "$cor3"."id" = "relatedpostid") AS "t6") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t9") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 2 AND CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-27 00:00:00'
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t13"
GROUP BY "$cor1"."userid") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-07-30 03:49:24'
GROUP BY "userid"
HAVING "userid" = "$cor0"."userid") AS "t18"