
WITH UserStats AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
MostActiveUsers AS (
    SELECT UserId, DisplayName, Reputation, PostCount,
           QuestionCount, AnswerCount, WikiCount, 
           Upvotes, Downvotes,
           RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM UserStats
),
TopBadgeHolders AS (
    SELECT U.Id AS UserId, 
           COUNT(B.Id) AS BadgeCount,
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
FinalStats AS (
    SELECT MA.UserId, MA.DisplayName, MA.Reputation, MA.PostCount,
           MA.QuestionCount, MA.AnswerCount, MA.WikiCount,
           MA.Upvotes, MA.Downvotes, 
           TB.BadgeCount, TB.GoldCount, TB.SilverCount, TB.BronzeCount
    FROM MostActiveUsers MA
    LEFT JOIN TopBadgeHolders TB ON MA.UserId = TB.UserId
    WHERE MA.PostRank <= 10
)
SELECT * 
FROM FinalStats
ORDER BY Reputation DESC, PostCount DESC;
