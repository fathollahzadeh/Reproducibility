
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(COALESCE(B.Class, 0)) AS BadgeCount,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostTypeStats AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostTypeCount,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.Score) AS MaxPostScore
    FROM PostTypes PT
    LEFT JOIN Posts P ON PT.Id = P.PostTypeId
    GROUP BY PT.Id, PT.Name
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.WikiCount,
    U.Upvotes,
    U.Downvotes,
    U.BadgeCount,
    U.AvgPostScore,
    PTS.PostTypeId,
    PTS.PostTypeName,
    PTS.PostTypeCount,
    PTS.AvgViewCount,
    PTS.MaxPostScore
FROM UserStats U
JOIN PostTypeStats PTS ON U.PostCount > 0
ORDER BY U.Reputation DESC, PTS.PostTypeCount DESC
LIMIT 100;
