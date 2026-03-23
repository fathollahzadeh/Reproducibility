SELECT COALESCE(SUM("$cor0"."$f4" * "t19"."EXPR$0"), 0)
FROM (SELECT "t16"."userid" AS "userid0", "$cor1"."EXPR$0" * "t16"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", COALESCE(SUM("$cor2"."$f5" * "t12"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."userid", "$cor3"."id0", "$cor3"."$f5" * "t9"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "$cor4"."id" AS "id0", "$cor4"."$f5" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "$cor5"."userid", "t2"."id", "$cor5"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid", "postid") AS "$cor5",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" <= 40 AND "commentcount" >= 0 AND ("creationdate" >= TIMESTAMP '2010-07-28 17:40:56' AND "creationdate" <= TIMESTAMP '2014-09-11 04:22:44')
GROUP BY "id"
HAVING "id" = "$cor5"."postid") AS "t2") AS "$cor4",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1
GROUP BY "relatedpostid"
HAVING "$cor4"."id" = "relatedpostid") AS "t6") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor3"."id0" = "postid") AS "t9") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t12"
GROUP BY "$cor2"."userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "userid" = "$cor1"."userid") AS "t16") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t19"