SELECT COALESCE(SUM("$cor0"."EXPR$0" * "t17"."EXPR$0"), 0)
FROM (SELECT "$cor1"."userid", COALESCE(SUM("$cor1"."$f5" * "t13"."EXPR$0"), 0) AS "EXPR$0"
FROM (SELECT "$cor2"."userid", "$cor2"."id0", "$cor2"."$f5" * "t9"."EXPR$0" AS "$f5"
FROM (SELECT "$cor3"."userid", "$cor3"."id" AS "id0", "$cor3"."$f5" * "t5"."EXPR$0" AS "$f5"
FROM (SELECT "$cor4"."userid", "t2"."id", "$cor4"."EXPR$0" * "t2"."EXPR$0" AS "$f5"
FROM (SELECT "userid", "postid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid", "postid") AS "$cor4",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "commentcount" >= 0
GROUP BY "id"
HAVING "id" = "$cor4"."postid") AS "t2") AS "$cor3",
LATERAL (SELECT "relatedpostid", COUNT(*) AS "EXPR$0"
FROM "postlinks"
GROUP BY "relatedpostid"
HAVING "$cor3"."id" = "relatedpostid") AS "t5") AS "$cor2",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 2
GROUP BY "postid"
HAVING "$cor2"."id0" = "postid") AS "t9") AS "$cor1",
LATERAL (SELECT "postid", COUNT(*) AS "EXPR$0"
FROM "votes"
WHERE "votetypeid" = 5
GROUP BY "postid"
HAVING "$cor1"."id0" = "postid") AS "t13"
GROUP BY "$cor1"."userid") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid"
HAVING "userid" = "$cor0"."userid") AS "t17"