SELECT COALESCE(SUM("$cor0"."$f5" * "t15"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f5" * "t11"."EXPR$0" AS "$f5"
FROM (SELECT "$cor2"."userid", "t7"."userid" AS "userid0", "$cor2"."$f4" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."userid", "t3"."owneruserid", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 1
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND "score" <= 29 AND ("creationdate" >= TIMESTAMP '2010-07-19 20:40:36' AND "creationdate" <= TIMESTAMP '2014-09-10 20:52:30')
GROUP BY "owneruserid"
HAVING "$cor3"."userid" = "owneruserid") AS "t3") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" <= 50
GROUP BY "userid"
HAVING "$cor2"."owneruserid" = "userid") AS "t7") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-08-25 19:05:46'
GROUP BY "userid"
HAVING "$cor1"."userid0" = "userid") AS "t11") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" <= 11 AND ("creationdate" >= TIMESTAMP '2010-07-31 17:32:56' AND "creationdate" <= TIMESTAMP '2014-09-07 16:06:26')
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t15"