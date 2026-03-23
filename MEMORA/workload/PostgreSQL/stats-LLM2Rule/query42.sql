SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t9"."EXPR$0"), 0)
FROM (SELECT "$cor1"."owneruserid", COALESCE(SUM("$cor1"."$f5" * "t5"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "t2"."id", "t2"."owneruserid", "$cor2"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid") AS "$cor2",
LATERAL (SELECT "id", "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "posttypeid" = 1 AND "score" >= -1 AND ("commentcount" >= 0 AND "commentcount" <= 11)
GROUP BY "id", "owneruserid"
HAVING "id" = "$cor2"."postid") AS "t2") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "postid"
HAVING "$cor1"."id" = "postid") AS "t5"
GROUP BY "$cor1"."owneruserid") AS "$cor0",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
GROUP BY "id"
HAVING "id" = "$cor0"."owneruserid") AS "t9"