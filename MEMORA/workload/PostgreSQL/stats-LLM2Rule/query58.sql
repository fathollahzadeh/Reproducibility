SELECT COALESCE(SUM("$cor0"."$f4" * "t19"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."$f4" * "t15"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."owneruserid", "$cor2"."$f4" * "t11"."EXPR$0" AS "$f4"
FROM (SELECT "$cor3"."owneruserid", "$cor3"."EXPR$0" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "$cor4"."owneruserid", COALESCE(SUM("$cor4"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" >= 0 AND "commentcount" <= 13
GROUP BY "id", "owneruserid") AS "$cor4",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "relatedpostid"
HAVING "$cor4"."id" = "relatedpostid") AS "t2"
GROUP BY "$cor4"."owneruserid") AS "$cor3",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 5 AND "creationdate" <= TIMESTAMP '2014-08-13 09:20:10'
GROUP BY "userid"
HAVING "$cor3"."owneruserid" = "userid") AS "t7") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) >= TIMESTAMP '2010-07-19 00:00:00'
GROUP BY "userid"
HAVING "$cor2"."owneruserid" = "userid") AS "t11") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-09-09 10:24:35'
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t15") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "downvotes" >= 0 AND ("creationdate" >= TIMESTAMP '2010-08-04 16:59:53' AND "creationdate" <= TIMESTAMP '2014-07-22 15:15:22')
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t19"