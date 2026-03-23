SELECT COALESCE(SUM("$cor0"."$f4" * "t9"."EXPR$0"), 0)
FROM (SELECT "t5"."userid", "$cor1"."$f4" * "t5"."EXPR$0" AS "$f4"
FROM (SELECT "t2"."owneruserid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND ("commentcount" >= 0 AND "commentcount" <= 15)
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor2"."userid") AS "t2") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t5") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND ("downvotes" >= 0 AND "downvotes" <= 1)
GROUP BY "id"
HAVING "$cor0"."userid" = "id") AS "t9"