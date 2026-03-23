SELECT COALESCE(SUM("$cor0"."$f5" * "t13"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f5" * "t9"."EXPR$0" AS "$f5"
FROM (SELECT "$cor2"."userid", "t6"."userid" AS "userid0", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."userid", "t3"."owneruserid", "$cor3"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 1
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -2 AND "score" <= 23 AND "viewcount" <= 2432 AND "commentcount" = 0 AND "favoritecount" >= 0
GROUP BY "owneruserid"
HAVING "$cor3"."userid" = "owneruserid") AS "t3") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid"
HAVING "$cor2"."owneruserid" = "userid") AS "t6") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."userid0" = "userid") AS "t9") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 113 AND ("views" >= 0 AND "views" <= 51)
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t13"