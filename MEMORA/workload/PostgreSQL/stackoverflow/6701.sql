WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        AVG(P.ViewCount) AS AverageViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.AverageScore,
        PS.AverageViews
    FROM UserReputation UR
    JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
    WHERE UR.ReputationRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.AverageScore,
    TU.AverageViews,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM TopUsers TU
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
) B ON TU.UserId = B.UserId
ORDER BY TU.Reputation DESC;
