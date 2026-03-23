SELECT COALESCE(SUM("$cor0"."$f4" * "t11"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0 AND "creationdate" <= TIMESTAMP '2014-09-13 20:12:15'
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "creationdate" >= TIMESTAMP '2010-07-27 01:51:15'
GROUP BY "owneruserid"
HAVING "$cor2"."userid" = "owneruserid") AS "t3") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" <= 50 AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-12 00:00:00'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t7") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" >= 0 AND "upvotes" <= 12 AND "creationdate" >= TIMESTAMP '2010-07-19 19:09:39'
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t11"