SELECT COALESCE(SUM("$cor0"."$f4" * "t17"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", "$cor1"."EXPR$0" * "t13"."EXPR$0" AS "$f4"
FROM (SELECT "$cor2"."owneruserid", COALESCE(SUM("$cor2"."$f5" * "t9"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor3"."id" AS "id0", "$cor3"."owneruserid", "$cor3"."$f5" * "t6"."EXPR$0" AS "$f5"
FROM (SELECT "t3"."id", "t3"."owneruserid", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0 AND "creationdate" <= TIMESTAMP '2014-09-09 19:58:29'
GROUP BY "postid") AS "$cor4",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -4 AND ("viewcount" >= 0 AND "viewcount" <= 5977) AND "answercount" <= 4 AND ("commentcount" >= 0 AND "commentcount" <= 11) AND "creationdate" >= TIMESTAMP '2011-01-25 08:31:41'
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor3"."id" = "postid") AS "t6") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t9"
GROUP BY "$cor2"."owneruserid") AS "$cor1",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "$cor1"."owneruserid" = "userid") AS "t13") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" <= 312 AND "downvotes" <= 0
GROUP BY "id"
HAVING "$cor0"."owneruserid" = "id") AS "t17"