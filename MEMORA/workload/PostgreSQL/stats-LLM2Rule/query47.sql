SELECT COALESCE(SUM("$cor0"."$f5" * "t14"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", "$cor1"."$f5" * "t10"."EXPR$0" AS "$f5"
FROM (SELECT "$cor2"."userid", "t6"."userid" AS "userid0", "$cor2"."$f4" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."userid", "t2"."owneruserid", "$cor3"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "$cor3",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" <= 13 AND ("answercount" >= 0 AND "answercount" <= 4) AND "commentcount" >= 0 AND "favoritecount" <= 2
GROUP BY "owneruserid"
HAVING "$cor3"."userid" = "owneruserid") AS "t2") AS "$cor2",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 3
GROUP BY "userid"
HAVING "$cor2"."owneruserid" = "userid") AS "t6") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "bountyamount" <= 50
GROUP BY "userid"
HAVING "$cor1"."userid0" = "userid") AS "t10") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" >= 0
GROUP BY "id"
HAVING "id" = "$cor0"."userid") AS "t14"