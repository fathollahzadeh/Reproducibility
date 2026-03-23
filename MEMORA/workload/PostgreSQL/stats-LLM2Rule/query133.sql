SELECT COALESCE(SUM("$cor0"."$f4" * "t13"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid0", "$cor1"."$f4" * "t9"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid0", "$cor2"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "t1"."userid" AS "userid0", "$cor3"."EXPR$0" * "t1"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "userid" = "$cor3"."userid") AS "t1") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-09-26 12:17:14'
GROUP BY "userid"
HAVING "$cor2"."userid0" = "userid") AS "t5") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" >= 0 AND (CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-20 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-11 00:00:00')
GROUP BY "userid"
HAVING "$cor1"."userid0" = "userid") AS "t9") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" = 0 AND ("upvotes" >= 0 AND "upvotes" <= 31) AND "creationdate" <= TIMESTAMP '2014-08-06 20:38:52'
GROUP BY "id"
HAVING "$cor0"."userid0" = "id") AS "t13"