SELECT COALESCE(SUM("$cor0"."$f4" * "t6"."EXPR$0"), 0)
FROM (SELECT "t2"."owneruserid", "$cor1"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "userid") AS "$cor1",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -1 AND ("commentcount" >= 0 AND "commentcount" <= 23)
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor1"."userid") AS "t2") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" = 0 AND ("upvotes" >= 0 AND "upvotes" <= 244)
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t6"