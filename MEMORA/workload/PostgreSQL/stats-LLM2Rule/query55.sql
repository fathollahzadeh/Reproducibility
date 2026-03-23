SELECT COALESCE(SUM("$cor0"."$f4" * "t14"."EXPR$0"), 0)
FROM (SELECT "$cor1"."id" AS "id1", "$cor1"."$f4" * "t10"."EXPR$0" AS "$f4"
FROM (SELECT "t7"."id", "$cor2"."EXPR$0" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "t2"."owneruserid", COALESCE(SUM("$cor3"."EXPR$0" * "t2"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "excerptpostid", COUNT(*) AS "EXPR$0"
FROM "tags"
GROUP BY "excerptpostid") AS "$cor3",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" >= 0
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor3"."excerptpostid") AS "t2"
GROUP BY "t2"."owneruserid") AS "$cor2",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" <= 0
GROUP BY "id"
HAVING "id" = "$cor2"."owneruserid") AS "t7") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid"
HAVING "$cor1"."id" = "userid") AS "t10") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-08-22 02:21:55'
GROUP BY "userid"
HAVING "$cor0"."id1" = "userid") AS "t14"