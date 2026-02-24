WITH UserBadgeCounts AS (
    SELECT U.Id AS UserId, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT P.OwnerUserId, 
           COUNT(P.Id) AS TotalPosts, 
           COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
           COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
           SUM(COALESCE(P.Score, 0)) AS TotalScore,
           SUM(P.ViewCount) AS TotalViews,
           AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserEngagement AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           U.CreationDate,
           U.LastAccessDate,
           COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
           PS.TotalPosts,
           PS.TotalQuestions,
           PS.TotalAnswers,
           PS.TotalScore,
           PS.TotalViews,
           PS.AverageScore
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    BadgeCount, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalScore, 
    TotalViews, 
    AverageScore,
    RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
FROM UserEngagement
WHERE Reputation > 1000
ORDER BY TotalScore DESC, Reputation DESC
LIMIT 50;
