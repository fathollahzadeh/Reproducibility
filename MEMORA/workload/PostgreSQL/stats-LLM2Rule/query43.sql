SELECT COALESCE(SUM("$cor0"."$f5" * "t10"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "$cor2"."userid", "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 3
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -7
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor2"."userid") AS "t3") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND ("upvotes" >= 0 AND "upvotes" <= 117)
GROUP BY "id"
HAVING "id" = "$cor1"."owneruserid") AS "t7") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor0"."userid" = "userid") AS "t10"