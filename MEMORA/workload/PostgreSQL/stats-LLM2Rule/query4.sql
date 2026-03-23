SELECT COALESCE(SUM("t"."EXPR$0" * "t1"."EXPR$0"), 0)
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "comments"
GROUP BY "userid") AS "t"
INNER JOIN (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 1 AND "creationdate" >= TIMESTAMP '2010-09-14 11:59:07'
GROUP BY "userid") AS "t1" ON "t"."userid" = "t1"."userid"