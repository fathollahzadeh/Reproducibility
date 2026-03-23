SELECT COALESCE(SUM("$cor0"."$f4" * "t8"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."userid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= 0 AND "score" <= 30 AND "commentcount" = 0 AND ("creationdate" >= TIMESTAMP '2010-07-27 15:30:31' AND "creationdate" <= TIMESTAMP '2014-09-04 17:45:10')
GROUP BY "owneruserid"
HAVING "$cor2"."userid" = "owneruserid") AS "t2") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."userid" = "userid") AS "t5") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t8"