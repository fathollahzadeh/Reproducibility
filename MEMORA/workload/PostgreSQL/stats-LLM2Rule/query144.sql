SELECT COALESCE(SUM("$cor0"."$f4" * "t17"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."EXPR$0" * "t13"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."owneruserid", COALESCE(SUM("$cor2"."$f5" * "t8"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."id" AS "id0", "$cor3"."owneruserid", "$cor3"."$f5" * "t5"."EXPR$0" AS "$f5"
FROM (SELECT "t2"."id", "t2"."owneruserid", "$cor4"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor4",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" >= 0 AND "commentcount" >= 0
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor4"."postid") AS "t2") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor3"."id" = "postid") AS "t5") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t8"
GROUP BY "$cor2"."owneruserid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-09-11 21:46:02'
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t13") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" >= 1 AND "reputation" <= 642 AND "downvotes" >= 0
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t17"