SELECT COALESCE(SUM("$cor0"."$f4" * "t14"."EXPR$0"), 0)
FROM (SELECT "t11"."id", "$cor1"."EXPR$0" * "t11"."EXPR$0" AS "$f4"
FROM (SELECT "t7"."owneruserid", COALESCE(SUM("$cor2"."$f4" * "t7"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."postid", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" <= TIMESTAMP '2014-09-13 20:12:15'
GROUP BY "postid") AS "$cor3",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "linktypeid" = 1 AND ("creationdate" >= TIMESTAMP '2011-09-03 21:00:10' AND "creationdate" <= TIMESTAMP '2014-07-30 21:29:52')
GROUP BY "relatedpostid"
HAVING "$cor3"."postid" = "relatedpostid") AS "t3") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= 0 AND "score" <= 23 AND ("answercount" >= 0 AND "answercount" <= 4) AND ("commentcount" >= 0 AND "commentcount" <= 10) AND "favoritecount" <= 9 AND ("creationdate" >= TIMESTAMP '2010-07-22 12:17:20' AND "creationdate" <= TIMESTAMP '2014-09-12 00:27:12')
GROUP BY "id", "owneruserid"
HAVING "$cor2"."postid" = "id") AS "t7"
GROUP BY "t7"."owneruserid") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "id" = "$cor1"."owneruserid") AS "t11") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor0"."id" = "userid") AS "t14"