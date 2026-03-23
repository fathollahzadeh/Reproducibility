SELECT COALESCE(SUM("$cor0"."$f4" * "t7"."EXPR$0"), 0)
FROM (SELECT "t3"."owneruserid", "$cor1"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" <= 5 AND ("commentcount" >= 0 AND "commentcount" <= 11) AND "favoritecount" <= 27
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor1"."userid") AS "t3") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t7"