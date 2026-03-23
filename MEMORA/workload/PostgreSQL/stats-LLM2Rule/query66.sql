SELECT COALESCE(SUM("$cor0"."$f4" * "t19"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t15"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", COALESCE(SUM("$cor2"."$f5" * "t10"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."userid", "$cor3"."id" AS "id0", "$cor3"."$f5" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "t3"."id", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-26 20:21:15' AND "creationdate" <= TIMESTAMP '2014-09-13 01:26:16'
GROUP BY "userid", "postid") AS "$cor4",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND "score" <= 19 AND "commentcount" <= 13
GROUP BY "id"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "postid"
HAVING "$cor3"."id" = "postid") AS "t6") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 2 AND "creationdate" <= TIMESTAMP '2014-08-07 12:06:00'
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t10"
GROUP BY "$cor2"."userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" <= 50 AND (CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-21 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-14 00:00:00')
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t15") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "creationdate" <= TIMESTAMP '2014-08-19 21:33:14'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t19"