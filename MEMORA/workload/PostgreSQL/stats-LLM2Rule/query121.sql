SELECT COALESCE(SUM("$cor0"."$f4" * "t11"."EXPR$0"), 0)
FROM (SELECT "t7"."id", "$cor1"."$f4" * "t7"."EXPR$0" AS "$f4"
FROM (SELECT "t3"."owneruserid", "$cor2"."EXPR$0" * "t3"."EXPR$0" AS "$f4"
FROM (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "posthistory"
WHERE "posthistorytypeid" = 2 AND ("creationdate" >= TIMESTAMP '2011-01-08 03:03:48' AND "creationdate" <= TIMESTAMP '2014-08-25 14:04:43')
GROUP BY "userid") AS "$cor2",
LATERAL (SELECT "owneruserid", COUNT(*) AS "EXPR$0"
FROM "posts"
WHERE "answercount" <= 4 AND ("commentcount" >= 0 AND "commentcount" <= 12) AND ("favoritecount" >= 0 AND "favoritecount" <= 89) AND "creationdate" <= TIMESTAMP '2014-09-02 10:21:04'
GROUP BY "owneruserid"
HAVING "owneruserid" = "$cor2"."userid") AS "t3") AS "$cor1",
LATERAL (SELECT "id", COUNT(*) AS "EXPR$0"
FROM "users"
WHERE "reputation" <= 705 AND ("creationdate" >= TIMESTAMP '2010-07-28 23:56:00' AND "creationdate" <= TIMESTAMP '2014-09-02 10:04:41')
GROUP BY "id"
HAVING "$cor1"."owneruserid" = "id") AS "t7") AS "$cor0",
LATERAL (SELECT "userid", COUNT(*) AS "EXPR$0"
FROM "badges"
WHERE "date" >= TIMESTAMP '2010-07-20 20:47:27' AND "date" <= TIMESTAMP '2014-09-09 13:24:28'
GROUP BY "userid"
HAVING "userid" = "$cor0"."id") AS "t11"