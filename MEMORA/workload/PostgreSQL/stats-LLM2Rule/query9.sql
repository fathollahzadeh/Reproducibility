SELECT COALESCE(SUM("$cor0"."$f4" * "t5"."EXPR$0"), 0)
FROM (SELECT "t2"."id", "$cor1"."EXPR$0" * "t2"."EXPR$0" AS "$f4"
FROM (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "postid") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" >= 0 AND "commentcount" <= 25
GROUP BY "id"
HAVING "id" = "$cor1"."postid") AS "t2") AS "$cor0",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
GROUP BY "postid"
HAVING "$cor0"."id" = "postid") AS "t5"