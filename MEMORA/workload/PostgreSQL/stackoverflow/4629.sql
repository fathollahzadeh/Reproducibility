WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
EnhancedStats AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.ReputationRank,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.TotalViews,
        PS.AverageScore,
        CASE 
            WHEN PS.TotalPosts IS NULL THEN 'No posts'
            WHEN PS.TotalPosts > 100 THEN 'Veteran'
            ELSE 'Newcomer' 
        END AS UserCategory,
        (SELECT STRING_AGG(B.Name, ', ') 
         FROM Badges B 
         WHERE B.UserId = UR.UserId) AS BadgeNames
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
)
SELECT 
    E.DisplayName,
    E.Reputation,
    E.ReputationRank,
    E.TotalPosts,
    E.Questions,
    E.Answers,
    E.TotalViews,
    COALESCE(E.AverageScore, 0) AS AverageScore,
    E.UserCategory,
    E.BadgeNames
FROM EnhancedStats E
WHERE E.ReputationRank <= 10
ORDER BY E.ReputationRank, E.TotalPosts DESC
LIMIT 5;