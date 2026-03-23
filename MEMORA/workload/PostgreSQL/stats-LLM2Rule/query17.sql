SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t6"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "creationdate" >= TIMESTAMP '2010-07-20 02:01:05'
GROUP BY "id", "owneruserid") AS "$cor1",
LATERAL (SELECT "excerptpostid", COUNT(*) AS "EXPR$0"
FROM "tags"
GROUP BY "excerptpostid"
HAVING "$cor1"."id" = "excerptpostid") AS "t2"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor0"."owneruserid" = "userid") AS "t6"