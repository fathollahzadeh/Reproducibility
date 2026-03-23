SELECT COALESCE(SUM("$cor0"."$f4" * "t20"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t16"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", COALESCE(SUM("$cor2"."$f5" * "t11"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."userid", "$cor3"."id" AS "id0", "$cor3"."$f5" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "t3"."id", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" <= TIMESTAMP '2014-09-11 13:24:22'
GROUP BY "userid", "postid") AS "$cor4",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND "score" = 2 AND "favoritecount" <= 12
GROUP BY "id"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" >= TIMESTAMP '2010-08-13 11:42:08' AND "creationdate" <= TIMESTAMP '2014-08-29 00:27:05'
GROUP BY "postid"
HAVING "$cor3"."id" = "postid") AS "t7") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2011-01-03 23:47:35' AND "creationdate" <= TIMESTAMP '2014-09-08 12:48:36'
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t11"
GROUP BY "$cor2"."userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-27 00:00:00'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t16") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "downvotes" >= 0
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t20"