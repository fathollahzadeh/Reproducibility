SELECT COALESCE(SUM("$cor0"."$f4" * "t19"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."EXPR$0" * "t15"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", COALESCE(SUM("$cor2"."$f5" * "t11"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."userid", "$cor3"."id" AS "id0", "$cor3"."$f5" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "t3"."id", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0 AND ("creationdate" >= TIMESTAMP '2010-08-02 20:27:48' AND "creationdate" <= TIMESTAMP '2014-09-10 16:09:23')
GROUP BY "userid", "postid") AS "$cor4",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND "score" = 4 AND "viewcount" <= 4937
GROUP BY "id"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" >= TIMESTAMP '2011-11-03 05:09:35'
GROUP BY "postid"
HAVING "$cor3"."id" = "postid") AS "t7") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 1
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t11"
GROUP BY "$cor2"."userid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t15") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" <= 270 AND ("views" >= 0 AND "views" <= 51) AND "downvotes" >= 0
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t19"