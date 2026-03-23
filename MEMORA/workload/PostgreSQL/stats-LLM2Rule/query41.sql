SELECT COALESCE(SUM("$cor0"."$f4" * "t12"."EXPR$0"), 0)
FROM (SELECT "t8"."id", "$cor1"."EXPR$0" * "t8"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", COALESCE(SUM("$cor2"."EXPR$0" * "t3"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" <= TIMESTAMP '2014-08-17 01:23:50'
GROUP BY "relatedpostid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND "score" <= 10 AND "answercount" <= 5 AND "commentcount" = 2 AND ("favoritecount" >= 0 AND "favoritecount" <= 6)
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."relatedpostid") AS "t3"
GROUP BY "t3"."owneruserid") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" <= 33 AND "downvotes" >= 0 AND ("creationdate" >= TIMESTAMP '2010-08-19 17:31:36' AND "creationdate" <= TIMESTAMP '2014-08-06 07:23:12')
GROUP BY "id"
HAVING "id" = "$cor1"."owneruserid") AS "t8") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-09-10 22:50:06'
GROUP BY "userid"
HAVING "$cor0"."id" = "userid") AS "t12"