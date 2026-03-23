SELECT COALESCE(SUM("t"."EXPR$0" * "t1"."EXPR$0"), 0)
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
GROUP BY "userid") AS "t"
INNER JOIN (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "upvotes" >= 0
GROUP BY "id") AS "t1" ON "t"."userid" = "t1"."id"