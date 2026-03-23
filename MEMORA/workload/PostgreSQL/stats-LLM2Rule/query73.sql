SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t18"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", COALESCE(SUM("$cor1"."$f5" * "t14"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor2"."userid", "$cor2"."id0", "$cor2"."$f5" * "t10"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."userid", "$cor3"."id" AS "id0", "$cor3"."$f5" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "t3"."id", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-22 01:19:43'
GROUP BY "userid", "postid") AS "$cor4",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND "viewcount" >= 0 AND "commentcount" <= 9
GROUP BY "id"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "relatedpostid"
HAVING "$cor3"."id" = "relatedpostid") AS "t6") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-09-20 17:45:15' AND "creationdate" <= TIMESTAMP '2014-08-07 01:00:45'
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t10") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 15
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t14"
GROUP BY "$cor1"."userid") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "userid" = "$cor0"."userid") AS "t18"