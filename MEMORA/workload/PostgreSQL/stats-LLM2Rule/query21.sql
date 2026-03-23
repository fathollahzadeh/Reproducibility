SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t8"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", COALESCE(SUM("$cor1"."EXPR$0" * "t3"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "postid", "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE CAST("creationdate" AS TIMESTAMP(0)) <= TIMESTAMP '2014-09-12 00:00:00'
GROUP BY "postid", "userid") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND ("creationdate" >= TIMESTAMP '2010-10-21 13:21:24' AND "creationdate" <= TIMESTAMP '2014-09-09 15:12:22')
GROUP BY "id"
HAVING "$cor1"."postid" = "id") AS "t3"
GROUP BY "$cor1"."userid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" >= 0 AND ("creationdate" >= TIMESTAMP '2010-07-27 17:15:57' AND "creationdate" <= TIMESTAMP '2014-09-03 12:47:42')
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t8"