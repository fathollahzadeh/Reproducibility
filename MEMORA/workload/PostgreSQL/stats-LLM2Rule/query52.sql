SELECT COALESCE(SUM("$cor0"."$f4" * "t13"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t9"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "$cor3"."userid", "$cor3"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND "score" <= 35 AND "answercount" = 1 AND "commentcount" <= 17 AND "favoritecount" >= 0
GROUP BY "owneruserid"
HAVING "$cor3"."userid" = "owneruserid") AS "t2") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "$cor2"."userid" = "userid") AS "t5") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-07-27 17:58:45' AND "date" <= TIMESTAMP '2014-09-06 17:33:22'
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t9") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" <= 233 AND "downvotes" <= 2 AND ("creationdate" >= TIMESTAMP '2010-09-16 16:00:55' AND "creationdate" <= TIMESTAMP '2014-08-24 21:12:02')
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t13"