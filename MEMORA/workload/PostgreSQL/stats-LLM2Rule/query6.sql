SELECT COALESCE(SUM("t0"."EXPR$0" * "t2"."EXPR$0"), 0)
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" <= TIMESTAMP '2014-09-11 08:55:52'
GROUP BY "userid") AS "t0"
INNER JOIN (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" >= 0 AND "answercount" <= 4 AND ("commentcount" >= 0 AND "commentcount" <= 17)
GROUP BY "owneruserid") AS "t2" ON "t0"."userid" = "t2"."owneruserid"