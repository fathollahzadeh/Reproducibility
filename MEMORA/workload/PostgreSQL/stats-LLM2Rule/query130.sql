SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t16"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", COALESCE(SUM("$cor1"."$f5" * "t11"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor2"."userid", "$cor2"."id" AS "id0", "$cor2"."$f5" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."userid", "t3"."id", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-11 12:25:05' AND "creationdate" <= TIMESTAMP '2014-09-11 13:43:09'
GROUP BY "userid", "postid") AS "$cor3",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" >= 0 AND "commentcount" <= 14
GROUP BY "id"
HAVING "$cor3"."postid" = "id") AS "t3") AS "$cor2",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1
GROUP BY "relatedpostid"
HAVING "relatedpostid" = "$cor2"."id") AS "t7") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-08-06 03:14:53'
GROUP BY "postid"
HAVING "postid" = "$cor1"."id0") AS "t11"
GROUP BY "$cor1"."userid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 491 AND "downvotes" = 0
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t16"