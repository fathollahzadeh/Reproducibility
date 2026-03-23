SELECT COALESCE(SUM("t0"."EXPR$0" * "t1"."EXPR$0"), 0)
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "t0"
INNER JOIN (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "votes"
GROUP BY "userid") AS "t1" ON "t0"."userid" = "t1"."userid"