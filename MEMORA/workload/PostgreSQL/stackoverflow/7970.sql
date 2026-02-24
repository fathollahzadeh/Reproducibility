WITH UserReputation AS (
    SELECT U.Id AS UserId, U.Reputation, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostMetrics AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS TotalPosts,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(P.ViewCount) AS TotalViews,
           SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT U.Id AS UserId, U.DisplayName, UR.Reputation, UR.BadgeCount,
           PM.TotalPosts, PM.QuestionCount, PM.AnswerCount, PM.TotalViews, PM.TotalScore
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PostMetrics PM ON U.Id = PM.OwnerUserId
),
RankedUsers AS (
    SELECT UA.*, 
           RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank,
           RANK() OVER (ORDER BY UA.TotalPosts DESC) AS PostRank
    FROM UserActivity UA
)
SELECT UserId, DisplayName, Reputation, BadgeCount,
       TotalPosts, QuestionCount, AnswerCount, TotalViews, TotalScore,
       ReputationRank, PostRank
FROM RankedUsers
WHERE TotalPosts > 10
ORDER BY ReputationRank, PostRank;
