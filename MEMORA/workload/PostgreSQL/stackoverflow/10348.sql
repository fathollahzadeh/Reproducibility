
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS Comments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        P.OwnerUserId
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TagWikis,
    US.Comments,
    COUNT(DISTINCT PS.PostId) AS TotalPostStats,
    SUM(PS.ViewCount) AS TotalViews,
    SUM(PS.Score) AS TotalScore
FROM UserStats US
LEFT JOIN PostStats PS ON US.UserId = PS.OwnerUserId
GROUP BY US.UserId, US.DisplayName, US.Reputation, 
         US.TotalPosts, US.Questions, US.Answers, US.TagWikis, US.Comments
ORDER BY US.Reputation DESC;
