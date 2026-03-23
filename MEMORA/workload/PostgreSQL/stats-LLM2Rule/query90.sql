SELECT COALESCE(SUM("$cor0"."$f4" * "t7"."EXPR$0"), 0)
FROM (SELECT "t3"."owneruserid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2011-05-20 18:43:03'
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "favoritecount" <= 5
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor1"."userid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "views" >= 0 AND "upvotes" >= 0 AND ("creationdate" >= TIMESTAMP '2010-11-27 21:46:49' AND "creationdate" <= TIMESTAMP '2014-08-18 13:00:22')
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t7"