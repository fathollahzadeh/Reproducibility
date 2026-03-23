SELECT COALESCE(SUM("t0"."EXPR$0" * "t2"."EXPR$0"), 0)
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
WHERE "score" = 0
GROUP BY "userid") AS "t0"
INNER JOIN (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-09-11 14:33:06'
GROUP BY "userid") AS "t2" ON "t0"."userid" = "t2"."userid"