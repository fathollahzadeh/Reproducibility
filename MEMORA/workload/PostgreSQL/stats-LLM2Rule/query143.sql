SELECT COALESCE(SUM("$cor0"."$f4" * "t22"."EXPR$0"), 0)
FROM (SELECT "t19"."userid" AS "userid0", "$cor1"."EXPR$0" * "t19"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", COALESCE(SUM("$cor2"."$f5" * "t14"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."userid", "$cor3"."id0", "$cor3"."$f5" * "t10"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "$cor4"."id" AS "id0", "$cor4"."$f5" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "$cor5"."userid", "t3"."id", "$cor5"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-08-01 19:11:47' AND "creationdate" <= TIMESTAMP '2014-09-11 13:42:51'
GROUP BY "userid", "postid") AS "$cor5",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" <= 4 AND "favoritecount" >= 0
GROUP BY "id"
HAVING "id" = "$cor5"."postid") AS "t3") AS "$cor4",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1
GROUP BY "relatedpostid"
HAVING "$cor4"."id" = "relatedpostid") AS "t7") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor3"."id0" = "postid") AS "t10") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 2 AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-10 00:00:00'
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t14"
GROUP BY "$cor2"."userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-08-02 12:24:29'
GROUP BY "userid"
HAVING "userid" = "$cor1"."userid") AS "t19") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t22"