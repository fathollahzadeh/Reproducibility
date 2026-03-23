SELECT COALESCE(SUM("$cor0"."$f4" * "t19"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."EXPR$0" * "t15"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."owneruserid", COALESCE(SUM("$cor2"."$f5" * "t11"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."id" AS "id0", "$cor3"."owneruserid", "$cor3"."$f5" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "t3"."id", "t3"."owneruserid", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "postid") AS "$cor4",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" >= 0 AND "answercount" <= 4 AND "creationdate" <= TIMESTAMP '2014-09-12 15:56:19'
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1 AND "creationdate" >= TIMESTAMP '2011-03-07 16:05:24'
GROUP BY "relatedpostid"
HAVING "$cor3"."id" = "relatedpostid") AS "t7") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" <= 100 AND (CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2009-02-03 00:00:00' AND CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-11 00:00:00')
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t11"
GROUP BY "$cor2"."owneruserid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t15") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" <= 160 AND ("creationdate" >= TIMESTAMP '2010-07-27 12:58:30' AND "creationdate" <= TIMESTAMP '2014-07-12 20:08:07')
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t19"