SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t19"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t14"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor2"."id0", "$cor2"."owneruserid", "$cor2"."$f5" * "t11"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."id" AS "id0", "$cor3"."owneruserid", "$cor3"."$f5" * "t7"."EXPR$0" AS "$f5"
FROM (SELECT "t3"."id", "t3"."owneruserid", "$cor4"."EXPR$0" * "t3"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "creationdate" >= TIMESTAMP '2010-07-26 19:37:03'
GROUP BY "postid") AS "$cor4",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "score" >= -2 AND "commentcount" <= 18 AND ("creationdate" >= TIMESTAMP '2010-07-21 13:50:08' AND "creationdate" <= TIMESTAMP '2014-09-11 00:53:10')
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor4"."postid") AS "t3") AS "$cor3",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
WHERE "creationdate" <= TIMESTAMP '2014-08-05 18:27:51'
GROUP BY "postid"
HAVING "$cor3"."id" = "postid") AS "t7") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "creationdate" >= TIMESTAMP '2010-11-27 03:38:45'
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t11") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t14"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "downvotes" >= 0 AND "upvotes" >= 0
GROUP BY "id"
HAVING "id" = "$cor0"."owneruserid") AS "t19"